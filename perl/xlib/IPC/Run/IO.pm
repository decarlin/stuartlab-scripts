package IPC::Run::IO ;

=head1 NAME

   IPC::Run::IO -- I/O channels for IPC::Run.

=head1 SYNOPSIS

   use IPC::Run qw( io ) ;

   ## The sense of '>' and '<' is opposite of perl's open(),
   ## but agrees with IPC::Run.
   $io = io( "filename", '>',  \$recv ) ;
   $io = io( "filename", 'r',  \$recv ) ;

   ## Append to $recv:
   $io = io( "filename", '>>', \$recv ) ;
   $io = io( "filename", 'ra', \$recv ) ;

   $io = io( "filename", '<',  \$send ) ;
   $io = io( "filename", 'w',  \$send ) ;

   $io = io( "filename", '<<', \$send ) ;
   $io = io( "filename", 'wa', \$send ) ;

   ## Handles / IO objects that the caller opens:
   $io = io( \*HANDLE,   '<',  \$send ) ;

   $f = IO::Handle->new( ... ) ; # Any subclass of IO::Handle
   $io = io( $f, '<', \$send ) ;

   require IPC::Run::IO ;
   $io = IPC::Run::IO->new( ... ) ;

   ## Then run(), harness(), or start():
   run $io, ... ;

   ## You can, of course, use io() or IPC::Run::IO->new() as an
   ## argument to run(), harness, or start():
   run io( ... ) ;


=head1 DESCRIPTION

This class and module allows filehandles and filenames to be harnessed for
I/O when used IPC::Run, independant of anything else IPC::Run is doing
(except that errors & exceptions can affect all things that IPC::Run is
doing).

=head1 SUBCLASSING

This class uses the fields pragma, so you need to be aware of the contraints
and strengths that this confers upon subclasses.
See the L<base> and L<fields> pragmas for more information.

=head1 TODO

Implement bidirectionality.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut ;

## This class is also used internally by IPC::Run in a very initimate way,
## since this is a partial factoring of code from IPC::Run plus some code
## needed to do standalone channels.  This factoring process will continue
## at some point.  Don't know how far how fast.

use strict ;
use Carp ;
use Fcntl ;
use Symbol ;
use UNIVERSAL qw( isa ) ;

require IPC::Run ;

use fields (
    'TYPE',             # Directionality
    'DEST',             # Where to send data to when reading from HANDLE
    'SOURCE',           # Where to get data from when writing to HANDLE
    'FILENAME',         # The filename to open & close, if any
    'HANDLE',           # This object's handle
    'FD',               # File descriptor of 'HANDLE'
    'TFD',              # fd# file is opened on in parent, will be moved to KFD
                        # in kid
    'KFD',              # fd# kid needs to see it on
    'FILTERS',          # Any filtration?
    'FBUFS',            # SCALAR refs to filter buffers, including I/O scalars
    'PAUSED',           # If the input side is paused.
    'SOURCE_EMPTY',     # No more data to send to file.
    'IS_DEBUG',         # This is the debug pipe
    'PTY_ID',           # The nickname of the pty it HANDLE is a pty
    'DONT_CLOSE',       # Set if this is an externally opened handle, so
                        # we know better than to close it.

    'KIN_REF',          # Refers to the input value, whether it's an externally
                        # supplied SCALAR, or the output buffer for an
			# externally supplied CODE ref.
    'TRUNC',            # Whether or not to truncate the output file if a
                        # named file is passed.
    'HARNESS',          # Temporarily set to the IPC::Run instance that
                        # called us while we're doing filters.  Unset to
			# prevent circrefs.
) ;

##
## some overly-friendly imports
##
sub _empty($) ;

*_debug = \&IPC::Run::_debug ;
*_empty = \&IPC::Run::_empty ;


sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my ( $external, $type, $internal ) = ( shift, shift, pop ) ;

   croak "$class: '$_' is not a valid I/O operator"
      unless $type =~ /^(?:<<?|>>?)$/ ;

   my IPC::Run::IO $self = _new_internal(
      $class, $type, undef, undef, $internal, @_
   ) ;

   if ( ! ref $external ) {
      $self->{FILENAME} = $external ;
   }
   elsif ( ref eq 'GLOB' || isa( $external, 'IO::Handle' ) ) {
      $self->{HANDLE} = $external ;
      $self->{DONT_CLOSE} = 1 ;
   }
   else {
      croak "$class: cannot accept " . ref( $external ) . " to do I/O with" ;
   }

   return $self ;
}


## IPC::Run uses this ctor, since it preparses things and needs more
## smarts.
sub _new_internal {
   my $class = shift ;
   $class = ref $class || $class ;

   my IPC::Run::IO $self ;
   {
      no strict 'refs' ;
      $self = bless [ \%{"$class\::FIELDS"} ], $class ;
   }

   my ( $type, $kfd, $pty_id, $internal, @filters ) = @_ ;

   # Older perls (<=5.00503, at least) don't do list assign to
   # psuedo-hashes well.
   $self->{TYPE}    = $type ;
   $self->{KFD}     = $kfd ;
   $self->{PTY_ID}  = $pty_id ;
   $self->{FILTERS} = [ @filters ] ;

   if ( $self->op =~ />/ ) {
      croak "'$_' missing a destination" if _empty $internal ;
      $self->{DEST} = $internal ;
      if ( isa( $self->{DEST}, 'CODE' ) ) {
	 ## Put a filter on the end of the filter chain to pass the
	 ## output on to the CODE ref.  For SCALAR refs, the last
	 ## filter in the chain writes on the scalar itself.  See
	 ## _init_filters().
	 unshift( 
	    @{$self->{FILTERS}},
	    sub {
	       my ( $in_ref ) = @_ ;

	       return IPC::Run::input_avail() && do {
		  $self->{DEST}->( $$in_ref ) ;
		  $$in_ref = '' ;
		  1 ;
	       }
	    }
	 ) ;
      }
   }
   else {
      croak "'$_' missing a source" if _empty $internal ;
      $self->{SOURCE} = $internal ;
      if ( isa( $internal, 'CODE' ) ) {
	 push(
	    @{$self->{FILTERS}},
	    sub {
	       my ( $in_ref, $out_ref ) = @_ ;
	       return 0 if length $$out_ref ;

	       return undef
		  if $self->{SOURCE_EMPTY} ;

	       my $in = $internal->() ;
	       unless ( defined $in ) {
		  $self->{SOURCE_EMPTY} = 1 ;
		  return undef 
	       }
	       return 0 unless length $in ;
	       $$out_ref = $in ;

	       return 1 ;
	    }
	 ) ;
      }
      elsif ( isa( $internal, 'SCALAR' ) ) {
	 push(
	    @{$self->{FILTERS}},
	    sub {
	       my ( $in_ref, $out_ref ) = @_ ;
	       return 0 if length $$out_ref ;

	       ## pump() clears auto_close_ins, finish() sets it.
	       return $self->{HARNESS}->{auto_close_ins} ? undef : 0
		  if IPC::Run::_empty ${$self->{SOURCE}}
		     || $self->{SOURCE_EMPTY} ;

	       $$out_ref = $$internal ;
	       eval { $$internal = '' }
		  if $self->{HARNESS}->{clear_ins} ;

	       $self->{SOURCE_EMPTY} = $self->{HARNESS}->{auto_close_ins} ;

	       return 1 ;
	    }
	 ) ;
      }
   }

   return $self ;
}


=item filename

Gets/sets the filename.  Returns the value after the name change, if
any.

=cut

sub filename {
   my IPC::Run::IO $self = shift ;
   $self->{FILENAME} = shift if @_ ;
   return $self->{FILENAME} ;
}


=item init

Does initialization required before this can be run.  This includes open()ing
the file, if necessary, and clearing the destination scalar if necessary.

=cut

sub init {
   my IPC::Run::IO $self = shift ;

   $self->{SOURCE_EMPTY} = 0 ;
   ${$self->{DEST}} = ''
      if $self->mode =~ /r/ && ref $self->{DEST} eq 'SCALAR' ;

   $self->open if defined $self->filename ;
   $self->{FD} = $self->fileno ;

   if ( ! $self->{FILTERS} ) {
      $self->{FBUFS} = undef ;
   }
   else {
      @{$self->{FBUFS}} = map {
	 my $s = "" ;
	 \$s ;
      } ( @{$self->{FILTERS}}, '' ) ;

      $self->{FBUFS}->[0] = $self->{DEST}
	 if $self->{DEST} && ref $self->{DEST} eq 'SCALAR' ;
      push @{$self->{FBUFS}}, $self->{SOURCE} ;
   }

   return undef ;
}


=item open

If a filename was passed in, opens it.  Determines if the handle is open
via fileno().  Throws an exception on error.

=cut

my %open_flags = (
   '>'  => O_RDONLY,
   '>>' => O_RDONLY,
   '<'  => O_WRONLY | O_CREAT | O_TRUNC,
   '<<' => O_WRONLY | O_CREAT | O_APPEND,
) ;

sub open {
   my IPC::Run::IO $self = shift ;

   croak "IPC::Run::IO: Can't open() a file with no name"
      unless defined $self->{FILENAME} ;
   $self->{HANDLE} = gensym unless $self->{HANDLE} ;

   IPC::Run::_debug(
      "opening '", $self->filename, "' mode '", $self->mode, "'"
   ) ;
   sysopen(
      $self->{HANDLE},
      $self->filename,
      $open_flags{$self->op},
   ) or croak
	 "IPC::Run::IO: $! opening '$self->{FILENAME}', mode '" . $self->mode . "'" ;

   return undef ;
}


=item close

Closes the handle.  Throws an exception on failure.


=cut

sub close {
   my IPC::Run::IO $self = shift ;

   if ( defined $self->{HANDLE} ) {
      close $self->{HANDLE}
	 or croak(  "IPC::Run::IO: $! closing "
	    . ( defined $self->{FILENAME}
	       ? "'$self->{FILENAME}'"
	       : "handle"
	    )
	 ) ;
   }
   else {
      IPC::Run::_close( $self->{FD} ) ;
   }

   $self->{FD} = undef ;

   return undef ;
}

=item fileno

Returns the fileno of the handle.  Throws an exception on failure.


=cut

sub fileno {
   my IPC::Run::IO $self = shift ;

   my $fd = fileno $self->{HANDLE} ;
   croak(  "IPC::Run::IO: $! "
         . ( defined $self->{FILENAME}
	    ? "'$self->{FILENAME}'"
	    : "handle"
	 )
      ) unless defined $fd ;

   return $fd ;
}

=item mode

Returns the operator in terms of 'r', 'w', and 'a'.  There is a state
'ra', unlike Perl's open(), which indicates that data read from the
handle or file will be appended to the output if the output is a scalar.
This is only meaningful if the output is a scalar, it has no effect if
the output is a subroutine.

The redirection operators can be a little confusing, so here's a reference
table:

   >      r      Read from handle in to process
   <      w      Write from process out to handle
   >>     ra     Read from handle in to process, appending it to existing
                 data if the destination is a scalar.
   <<     wa     Write from process out to handle, appending to existing
                 data if IPC::Run::IO opened a named file.

=cut

sub mode {
   my IPC::Run::IO $self = shift ;

   croak "IPC::Run::IO: unexpected arguments for mode(): @_" if @_ ;

   ## TODO: Optimize this
   return ( $self->{TYPE} =~ /</     ? 'w' : 'r' ) . 
          ( $self->{TYPE} =~ /<<|>>/ ? 'a' : ''  ) ;
}


=item op

Returns the operation: '<', '>', '<<', '>>'.  See L</mode> if you want
to spell these 'r', 'w', etc.

=cut

sub op {
   my IPC::Run::IO $self = shift ;

   croak "IPC::Run::IO: unexpected arguments for op(): @_" if @_ ;

   return $self->{TYPE} ;
}

##
## Filter Scaffolding
##
#my $filter_op  ;        ## The op running a filter chain right now
#my $filter_num ;        ## Which filter is being run right now.

use vars (
'$filter_op',        ## The op running a filter chain right now
'$filter_num'        ## Which filter is being run right now.
) ;

sub _init_filters {
   my IPC::Run::IO $self = shift ;

confess "\$self not an IPC::Run::IO" unless isa( $self, "IPC::Run::IO" ) ;
   $self->{FBUFS} = [] ;

   $self->{FBUFS}->[0] = $self->{DEST}
      if $self->{DEST} && ref $self->{DEST} eq 'SCALAR' ;

   return unless $self->{FILTERS} && @{$self->{FILTERS}} ;

   push @{$self->{FBUFS}}, map {
      my $s = "" ;
      \$s ;
   } ( @{$self->{FILTERS}}, '' ) ;

   push @{$self->{FBUFS}}, $self->{SOURCE} ;
}



sub _do_filters {
   my IPC::Run::IO $self = shift ;

   ( $self->{HARNESS} ) = @_ ;

   my ( $saved_op, $saved_num ) =($IPC::Run::filter_op,$IPC::Run::filter_num) ;
   $IPC::Run::filter_op = $self ;
   $IPC::Run::filter_num = -1 ;
   my $r = eval { IPC::Run::get_more_input() ; } ;
   ( $IPC::Run::filter_op, $IPC::Run::filter_num ) = ( $saved_op, $saved_num ) ;
   $self->{HARNESS} = undef ;
   die $@ if $@ ;
   return $r ;
}

1 ;
