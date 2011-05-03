package IPC::Run ;

#
# Copyright (c) 1999 by Barrie Slaymaker, barries@slaysys.com
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=head1 NAME

IPC::Run - Run subprocesses w/ piping, redirection, and pseudo-ttys

=head1 SYNOPSIS

   use IPC::Run (
      qw( run ),                       # Batch mode API
      qw( harness start pump finish ), # Intermittent API
      qw( io timer timeout ),          # Helper objects.
   ) ;

   my @cat = qw( cat in.txt - ) ;

   ## Running a command with stdin closed, output redirected
   ## to scalars and a 10 second timeout:
   run \@cat, \undef, \$out, \$err, timeout( 10 )
      or die "cat returned $?";

   ## Redirecting stdin from various scalars:
   $in = "input" ;
   run \@cat, \$in,      \$out, \$err, ... ;
   run \@cat, \"input",  \$out, \$err, ... ;
   run \@cat, \<<TOHERE, \$out, \$err, ... ;
   input
   TOHERE

   ## I/O redirection using functions, filenames.  You can mix
   ## techniques, too.
   run \@cat, \&in,      \&out, \&err ... ;
   run \@cat, '<', $in_filename, '>', $out_name, '2>', $err_name ... ;

   ## Redirecting using psuedo-terminals.
   run \@cat, '<pty<', \$in,  '>pty>', \$out_and_err ;
   run \@cat, '<pty<', \&in,  '>pty>', \&out_and_err ;

   # Incrementally read from / write to scalars.  Note that $in_q
   # is a queue that is drained as it is used, which is not the
   # way run() treats inputs.  $h is for "harness".
      my $h = start(
         \@cat, \$in_q, \$out_q, \$err_q,
	 timeout( name => "process timeout", 10 ),
	 $stall_timeout = timeout( name => "stall timeout", 5 ),
      ) ;

      $in_q .= "some input\n" ;
      $stall_timeout->start ;
      pump $h until $out_q =~ /input/ ;
      warn $err_q ; 
      $err_q = '' ;
      $out_q = '' ;

      $stall_timeout->start ;
      $in_q .= "some more input\n" ;
      pump $h until $out_q =~ /input/ ;
      warn $err_q ; 
      $err_q = '' ;

      $in_q .= "some final input\n" ;
      $h->timeout( "1:00" ) ;
      $stall_timeout->start ;
      finish $h or die "cat returned $?" ;
      warn $err_q ; 
      print $out_q ;

   # Piping between children
      run \@cat, '|', [qw(gzip)] ;

   # Multiple children simultaneously (run() blocks until all
   # children exit, use start() for background execution):
      run [qw(foo1)], '&', [qw(foo2)] ;

   # Spawning a subroutine (only on systems with true fork()/exec())
      run \&child_sub, \$in, \$out ;

   # Calling \&set_up_child in the child before it executes the
   # command (only works on systems with true fork() & exec())
      run \@cat, \$in, \$out,
         init => \&set_up_child ;

   # Append output to named files
      run( \@cat, '>>', $out_f_name, '2>>', $err_f_name ) ;

   # Read from / write to file handles you open and close
      open IN,  '<in.txt'  or die $! ;
      open OUT, '>out.txt' or die $! ;
      print OUT "preamble\n" ;
      run \@cat, \*IN, \*OUT or die "cat returned $?" ;
      print OUT "postamble\n" ;
      close IN ;
      close OUT ;

   # Create pipes for you to read / write (like IPC::Open2 & 3).
      $h = start
         \@cat,
	    '<pipe', \*IN,
	    '>pipe', \*OUT,
	    '2>pipe', \*ERR 
	 or die "cat returned $?" ;
      print IN "some input\n" ;
      close IN ;
      print <OUT>, <ERR> ;
      finish $h ;

   # Mixing input and output modes
      run \@cat, 'in.txt', \&catch_some_out, \*ERR_LOG ) ;

   # Other redirection constructs
      run \@cat, '>&', \$out_and_err ;
      run \@cat, '2>&1' ;
      run \@cat, '0<&3' ;
      run \@cat, '<&-' ;
      run \@cat, '3<', \$in3 ;
      run \@cat, '4>', \$out4 ;
      # etc.

   # Passing options:
      run \@cat, 'in.txt', debug => 1 ;

   # Call this system's shell, returns TRUE on 0 exit code
   # THIS IS THE OPPOSITE SENSE OF system()'s RETURN VALUE
      run "cat a b c" or die "cat returned $?" ;

   # Launch a sub process directly, no shell.  Can't do redirection
   # with this form, it's here to behave like system() with an
   # inverted result.
      $r = run "cat a b c" ;

   # Read from a file in to a scalar
      run io( "filename", 'r', \$recv ) ;
      run io( \*HANDLE,   'r', \$recv ) ;

=head1 DESCRIPTION

IPC::Run allows you run and interact with child processes, files, pipes,
and pseudo-ttys.  Both event-loop and procedural techniques are supported
and may be mixed.  Likewise, functional and OO API styles are both
supported and may be mixed.

Various redirection operators reminiscent of those
seen on common Unix and DOS command lines are provided.

=head2 Harnesses

Child processes and I/O handles are gathered in to a harness, then run
until the processing is finished or aborted.

=head2 run() vs. start(); pump(); finish();

There are two modes you can run harnesses in: incremental and batch.
In incremental mode, you use start() and pump() to activate the harness
and interact with it, then switch to batch mode and
use run() or finish() to let the harness run to completion.

In batch mode, you just use run() or start() and finish() and let things
run to completion.

In batch mode, all data to be sent to the harness is set up
in advance, the harness is run and all output is collected from it, then
any child processes are waited for:

   run \@cmd, \<<IN, \$out ;
   blah
   IN

Incremental mode is provided by start(), pump(), and finish():

   my $h = start \@cat, \$in_q, \$out_q, \$err_q ;
   $in_q = "first input\n" ;

   pump $h while length $in_q ;
   warn $err_q if length $err_q ; 
   $err_q = '' ;

   $in_q = "second input\n" ;
   pump $h until $out_q =~ /second input/ ;

   $h->finish ;

You can compile the harness with harness() prior to start()ing, and you
may omit start() between harness() and pump().  You might want
to do these things if you compile your harnesses ahead of time.

You may call timeout() at any time in this process.  If it is called
before start() (or the first pump(), if start() is omitted), then the
timer is started just after all the child processes have been fork()ed
or spawn()ed.

If you call it once the children have been start()ed, the timeout timer
is restarted.  So this sequence:

   my $h = harness \@cat, \$in_q, \$out_q, \$err_q ;
   $h->timeout( 10 ) ;
   sleep 11 ;  # No effect: timer not running yet

   start $h ;
   $in_q = "foo\n" ;
   pump $h until ! length $in_q ;
   ## 10 (or little more) may pass til this line.

   $in_q = "bar\n" ;
   $h->timeout( 1 ) ;
   ## Timer is now running, but will elapse after 1 second
   pump $h until ! length $in_q ;
   ## 1 seconds (or a little more) may pass til this line.

   $h->timeout( 30 ) ;
   $h->finish ;

The timeout does not include the time it takes to wait for the children
to exit, either.

=head2 Syntax

run(), start(), and harness() can all take a harness specification
as input.  A harness specification is either a single string to be passed
to the systems' shell:

   run "echo 'hi there'" ;

or a list of commands, io operations, and/or timers/timeouts to execute.
Consecutive commands must be separated by a pipe operator '|' or an
'&'.  External commands are
passed in as array references, and, on systems supporting fork(),
Perl code may be passed in as subs:

   run \@cmd ;
   run \@cmd1, '|', \@cmd2 ;
   run \@cmd1, '&', \@cmd2 ;
   run \&sub1 ;
   run \&sub1, '|', \&sub2 ;
   run \&sub1, '&', \&sub2 ;

'|' pipes the stdout of \@cmd1 the stdin of \@cmd2, just like a
shell pipe.  '&' does not.  Child processes to the right of a '&'
will have their stdin closed unless it's redirected-to.

L<IPC::Run::IO> objects may be passed in as well, whether or not
child processes are also specified:

   run io( "infile", ">", \$in ), io( "outfile", "<", \$in ) ;
      
as can L<IPC::Run::Timer> objects:

   run \@cmd, io( "outfile", "<", \$in ), timeout( 10 ) ;

Commands may be followed by scalar, sub, or i/o handle references for
redirecting
child process input & output:

   run \@cmd,  \undef,            \$out ;
   run \@cmd,  \$in,              \$out ;
   run \@cmd1, \&in, '|', \@cmd2, \*OUT ;
   run \@cmd1, \*IN, '|', \@cmd2, \&out ;

This is known as succinct redirection syntax, since run(), start()
and harness(), figure out which file descriptor to redirect and how.
File descriptor 0 is presumed to be an input for
the child process, all others are outputs.  The assumed file
descriptor always starts at 0, unless the command is being piped to,
in which case it starts at 1.

To be explicit about your redirects, or if you need to do more complex
things, there's also a redirection operator syntax:

   run \@cmd, '<', \undef, '>',  \$out ;
   run \@cmd, '<', \undef, '>&', \$out_and_err ;
   run(
      \@cmd1,
         '<', \$in,
      '|', \@cmd2,
         \$out
   ) ;

Operator syntax is required if you need to do something other than simple
redirection to/from scalars or subs, like duping or closing file descriptors
or redirecting to/from a named file.  The operators are covered in detail
below.

After each \@cmd (or \&foo), parsing begins in succinct mode and toggles to
operator syntax mode when an operator (ie plain scalar, not a ref) is seen.
Once in
operator syntax mode, parseing only reverts to succinct mode when a '|' or
'&' is seen.

In succinct mode, each parameter after the \@cmd specifies what to
do with the next highest file descriptor. These File descriptor start
with 0 (stdin) unless stdin is being piped to (C<'|', \@cmd>), in which
case they start with 1 (stdout).  Currently, being on the left of
a pipe (C<\@cmd, \$out, \$err, '|'>) does I<not> cause stdout to be
skipped, though this may change since it's not as DWIMerly as it
could be.  Only stdin is assumed to be an
input in succinct mode, all others are assumed to be outputs.

If no piping or redirection is specified for a child, it will
inherit the parent's open file descriptors as dictated by your
system's close-on-exec behavior and the $^F flag, except that
processes after a '&' will not inherit the parent's stdin.  Such
processes will have their stdin closed unless it has been redirected-to.

If you want to close a child processes stdin, you may do any of:

   run \@cmd, \undef ;
   run \@cmd, \"" ;
   run \@cmd, '<&-' ;
   run \@cmd, '0<&-' ;

Redirection is done by placing redirection specifications immediately 
after a command or child subroutine:

   run \@cmd1,      \$in, '|', \@cmd2,      \$out ;
   run \@cmd1, '<', \$in, '|', \@cmd2, '>', \$out ;

If you omit the redirection operators, descriptors are counted
starting at 0.  Descriptor 0 is assumed to be input, all others
are outputs.  A leading '|' consumes descriptor 0, so this
works as expected.

   run \@cmd1, \$in, '|', \@cmd2, \$out ;
   
The parameter following a redirection operator can be a scalar ref,
a subroutine ref, a file name, an open filehandle, or a closed
filehandle.

If it's a scalar ref, the child reads input from or sends output to
that variable:

   $in = "Hello World.\n" ;
   run \@cat, \$in, \$out ;
   print $out ;

Scalars used in incremental (start()/pump()/finish()) applications are treated
as queues: input is removed from input scalers, resulting in them dwindling
to '', and output is appended to output scalars.  This is not true of 
harnesses run() in batch mode.

It's usually wise to append new input to be sent to the child to the input
queue, and you'll often want to zap output queues to '' before pumping.

   $h = start \@cat, \$in_q ;
   $in_q = "line 1\n" ;
   pump $h ;
   $in_q .= "line 2\n" ;
   pump $h ;
   $in_q .= "line 3\n" ;
   finish $h ;

The final call to finish() must be there: it allows the child process(es)
to run to completion and waits for their exit values.

=head1 OBSTINATE CHILDREN

Interactive applications are usually optimized for human use.  This
can help or hinder trying to interact with them through modules like
IPC::Run.  Frequently, programs alter their behavior when they detect
that stdin, stdout, or stderr are not connected to a tty, assuming that
they are being run in batch mode.  Whether this helps or hurts depends
on which optimizations change.  And there's often no way of telling
what a program does in these areas other than trial and error and,
occasionally, reading the source.  This includes different versions
and implementations of the same program.

All hope is not lost, however.  Most programs behave in reasonably
tractable manners, once you figure out what it's trying to do.

Here are some of the issues you might need to be aware of.

=over

=item *

fflush()ing stdout and stderr

This lets the user see stdout and stderr immediately.  Many programs
undo this optimization if stdout is not a tty, making them harder to
manage by things like IPC::Run.

Many programs decline to fflush stdout or stderr if they do not
detect a tty there.  Some ftp commands do this, for instance.

If this happens to you, look for a way to force interactive behavior,
like a command line switch or command.  If you can't, you will
need to use a pseudo terminal ('<pty<' and '>pty>').

=item *

false prompts

Interactive programs generally do not guarantee that output from user
commands won't contain a prompt string.  For example, your shell prompt
might be a '$', and a file named '$' might be the only file in a directory
listing.

This can make it hard to guarantee that your output parser won't be fooled
into early termination of results.

To help work around this, you can see if the program can alter it's 
prompt, and use something you feel is never going to occur in actual
practice.

You should also look for your prompt to be the only thing on a line:

   pump $h until $out =~ /^<SILLYPROMPT>\s?\z/m ;

(use C<(?!\n)\Z> in place of C<\z> on older perls).

You can also take the approach that IPC::ChildSafe takes and emit a
command with known output after each 'real' command you issue, then
look for this known output.  See new_appender() and new_chunker() for
filters that can help with this task.

If it's not convenient or possibly to alter a prompt or use a known
command/response pair, you might need to autodetect the prompt in case
the local version of the child program is different then the one
you tested with, or if the user has control over the look & feel of
the prompt.

=item *

Refusing to accept input unless stdin is a tty.

Some programs, for security reasons, will only accept certain types
of input from a tty.  su, notable, will not prompt for a password unless
it's connected to a tty.

If this is your situation, use a pseudo terminal ('<pty<' and '>pty>').

=item *

Not prompting unless connected to a tty.

Some programs don't prompt unless stdin or stdout is a tty.  See if you can
turn prompting back on.  If not, see if you can come up with a command that
you can issue after every real command and look for it's output, as
IPC::ChildSafe does.   There are two filters included with IPC::Run that
can help with doing this: appender and chunker (see new_appender() and
new_chunker()).

=item *

Different output format when not connected to a tty.

Some commands alter their formats to ease machine parsability when they
aren't connected to a pipe.  This is actually good, but can be suprising.

=back

=head1 PSEUDO TERMINALS

On systems providing pseudo terminals under /dev, IPC::Run can use IO::Pty
(available on CPAN) to provide a terminal environment to subprocesses.
This is necessary when the subprocess really wants to think it's connected
to a real terminal.

=head2 CAVEATS

Psuedo-terminals are not pipes, though they are similar.  Here are some
differences to watch out for.

=over

=item Echoing

Sending to stdin will cause an echo on stdout, which occurs before each line
is passed to the child program.  There is currently no way to disable this.

=item Shutdown

IPC::Run cannot close a pty until all output has been collected.  This means
that it is not possible to send an EOF to stdin by half-closing the pty, as
we can when using a pipe to stdin.

This means that you need to send the
child process an exit command or signal, or run() / finish() will time out.
Be careful not to expect a prompt after sending the exit command.

=item Command line editing

Some subprocesses, notable shells that depend on the user's prompt settings,
will reissue the prompt plus the command line input so far once for each
character.

=item '>pty>' means '&>pty>', not '1>pty>'

The pseudo terminal redirects both stdin and stdout unless you specify
a file desciptor.  If you want to grab stderr separately, do this:

   start \@cmd, '<pty<', \$in, '>pty>', \$out, '2>', \$err ;

=item stdin, stdout, and stderr not inherited

Child processes harnessed to a pseudo terminal have their stdin, stdout,
and stderr completely closed before any redirection operators take
effect.  This casts of the bonds of the controlling terminal.  This is
not done when using pipes.

Right now, this affects all children in a harness that has a pty in
use, even if that pty would not affect a particular child.  That's a bug
and will be fixed.  Until it is, it's best not to mix-and-match
children.

=back

=head2 Redirection Operators

   Operator       SHNP   Description
   ========       ====   ===========
   <, N<          SHN    Redirects input to a child's fd N (0 assumed)

   >, N>          SHN    Redirects output from a child's fd N (1 assumed)
   >>, N>>        SHN    Like '>', but appends to scalars or named files
   >&, &>         SHN    Redirects stdout & stderr from a child process

   <pty, N<pty    S      Like '<', but uses a pseudo-tty instead of a pipe
   >pty, N>pty    S      Like '>', but uses a pseudo-tty instead of a pipe

   N<&M                  Dups input fd N to input fd M
   M>&N                  Dups output fd N to input fd M
   N<&-                  Closes fd N

   <pipe, N<pipe     P   Pipe opens H for caller to read, write, close.
   >pipe, N>pipe     P   Pipe opens H for caller to read, write, close.
                      


'N' and 'M' are placehodlers for integer file descriptor numbers.  The
terms 'input' and 'output' are from the child process's perspective.

The SHNP field indicates what parameters an operator can take:

   S: \$scalar or \&function references.  Filters may be used with
      these operators (and only these).
   H: \*HANDLE or IO::Handle for caller to open, and close
   N: "file name".
   P: \*HANDLE opened by IPC::Run as the parent end of a pipe, but read
      and written to and closed by the caller (like IPC::Open3).

=over

=item Redirecting input: [n]<, [n]<pipe

You can input the child reads on file descriptor number n to come from a
scalar variable, subroutine, file handle, or a named file.  If stdin
is not redirected, the parent's stdin is inherited.

   run \@cat, \undef          ## Closes child's stdin immediately
      or die "cat returned $?" ; 

   run \@cat, \$in ;

   run \@cat, \<<TOHERE ;
   blah
   TOHERE

   run \@cat, \&input ;       ## Calls &input, feeding data returned
                              ## to child's.  Closes child's stdin
			      ## when undef is returned.

Redirecting from named files requires you to use the input
redirection operator:

   run \@cat, '<.profile' ;
   run \@cat, '<', '.profile' ;

   open IN, "<foo" ;
   run \@cat, \*IN ;
   run \@cat, *IN{IO} ;

The form used second example here is the safest,
since filenames like "0" and "&more\n" won't confuse &run:

You can't do either of

   run \@a, *IN ;      ## INVALID
   run \@a, '<', *IN ; ## BUGGY: Reads file named like "*main::A"
   
because perl passes a scalar containing a string that
looks like "*main::A" to &run, and &run can't tell the difference
between that and a redirection operator or a file name.  &run guarantees
that any scalar you pass after a redirection operator is a file name.

If your child process will take input from file descriptors other
than 0 (stdin), you can use a redirection operator with any of the
valid input forms (scalar ref, sub ref, etc.):

   run \@cat, '3<', \$in3_q ;

When redirecting input from a scalar ref, the scalar ref is
used as a queue.  This allows you to use &harness and pump() to
feed incremental bits of input to a coprocess.  See L</Coprocesses>
below for more information.

The <pipe operator opens the write half of a pipe on the filehandle
glob reference it takes as an argument:

   $h = start \@cat, '<pipe', \*IN ;
   print IN "hello world\n" ;
   pump $h ;
   close IN ;
   finish $h ;

Unlike the other '<' operators, IPC::Run does nothing further with
it: you are responsible for it.  The previous example is functionally
equivalent to:

   pipe( \*R, \*IN ) or die $! ;
   $h = start \@cat, '<', \*IN ;
   print IN "hello world\n" ;
   pump $h ;
   close IN ;
   finish $h ;

This is like the behavior of IPC::Open2 and IPC::Open3.

=item Redirecting output: [n]>, [n]>>, [n]>&[m], [n]>pipe

You can redirect any output the child emits
to a scalar variable, subroutine, file handle, or file name.  You
can have &run truncate or append to named files or scalars.  If
you are redirecting stdin as well, or if the command is on the
receiving end of a pipeline ('|'), you can omit the redirection
operator:

   @ls = ( 'ls' ) ;
   run \@ls, \undef, \$out
      or die "ls returned $?" ; 

   run \@ls, \undef, \&out ;  ## Calls &out each time some output
                              ## is received from the child's 
			      ## when undef is returned.

   run \@ls, \undef, '2>ls.err' ;
   run \@ls, '2>', 'ls.err' ;

The two parameter form guarantees that the filename
will not be interpreted as a redirection operator:

   run \@ls, '>', "&more" ;
   run \@ls, '2>', ">foo\n" ;

You can pass file handles you've opened for writing:

   open( *OUT, ">out.txt" ) ;
   open( *ERR, ">err.txt" ) ;
   run \@cat, \*OUT, \*ERR ;

Passing a scalar reference and a code reference requires a little
more work, but allows you to capture all of the output in a scalar
or each piece of output by a callback:

These two do the same things:

   run( [ 'ls' ], '2>', sub { $err_out .= $_[0] } ) ;

does the same basic thing as:

   run( [ 'ls' ], '2>', \$err_out ) ;

The subroutine will be called each time some data is read from the child.

The >pipe operator is different in concept than the other '>' operators,
although it's syntax is similar:

   $h = start \@cat, $in, '>pipe', \*OUT, '2>pipe', \*ERR ;
   $in = "hello world\n" ;
   finish $h ;
   print <OUT> ;
   print <ERR> ;
   close OUT ;
   close ERR ;

causes two pipe to be created, with one end attached to cat's stdout
and stderr, respectively, and the other left open on OUT and ERR, so
that the script can manually
read(), select(), etc. on them.  This is like
the behavior of IPC::Open2 and IPC::Open3.

=item Duplicating output descriptors: >&m, n>&m

This duplicates output descriptor number n (default is 1 if n is ommitted)
from descriptor number m.

=item Duplicating input descriptors: <&m, n<&m

This duplicates input descriptor number n (default is 0 if n is ommitted)
from descriptor number m

=item Closing descriptors: <&-, 3<&-

This closes descriptor number n (default is 0 if n is ommitted).  The
following commands are equivalent:

   run \@cmd, \undef ;
   run \@cmd, '<&-' ;
   run \@cmd, '<in.txt', '<&-' ;

Doing

   run \@cmd, \$in, '<&-' ;    ## SIGPIPE recipe.

is dangerous: the parent will get a SIGPIPE if $in is not empty.

=item Redirecting both stdout and stderr: &>, >&, &>pipe, >pipe&

The following pairs of commands are equivalent:

   run \@cmd, '>&', \$out ;       run \@cmd, '>', \$out,     '2>&1' ;
   run \@cmd, '>&', 'out.txt' ;   run \@cmd, '>', 'out.txt', '2>&1' ;

etc.

File descriptor numbers are not permitted to the left or the right of
these operators, and the '&' may occur on either end of the operator.

The '&>pipe' and '>pipe&' variants behave like the '>pipe' operator, except
that both stdout and stderr write to the created pipe.

=item Redirection Filters

Both input redirections and output redirections that use scalars or
subs as endpoints may have an arbitrary number of filter subs placed
between them and the child process.  This is useful if you want to
receive output in chunks, or if you want to massage each chunk of
data sent to the child.  To use this feature, you must use operator
syntax:

   run(
      \@cmd
         '<', \&in_filter_2, \&in_filter_1, $in,
         '>', \&out_filter_1, \&in_filter_2, $out,
   ) ;

This capability is not provided for IO handles or named files.

Two filters are provided by IPC::Run: appender and chunker.  Because
these may take an argument, you need to use the constructor fuinctions
new_appender() and new_chunker() rather than using \& syntax:

   run(
      \@cmd
         '<', new_appender( "\n" ), $in,
         '>', new_chunker, $out,
   ) ;

=back

=head2 Just doing I/O

If you just want to do I/O to a handle or file you open yourself, you
may specify a filehandle or filename instead of a command in the harness
specification:

   run io( "filename", '>', \$recv ) ;

   $h = start io( $io, '>', \$recv ) ;

   $h = harness \@cmd, '&', io( "file", '<', \$send ) ;

=head2 Options

Options are passed in as name/value pairs:

   run \@cat, \$in, debug => 1 ;

If you pass the debug option, you may want to pass it in first, so you
can see what parsing is going on:

   run debug => 1, \@cat, \$in ;

=over

=item debug

Enables debugging output in parent and child.  Children emit debugging
info over a separate, dedicated pipe to the parent, so you must pump(),
pump_nb(), or finish() if you use start().  This pipe is not created
unless debugging is enabled.

=back

=head1 RETURN VALUES

harness() and start() return a reference to an IPC::Run harness.  This is
blessed in to the IPC::Run package, so you may make later calls to
functions as members if you like:

   $h = harness( ... ) ;
   $h->start ;
   $h->pump ;
   $h->finish ;

   $h = start( .... ) ;
   $h->pump ;
   ...

Of course, using method call syntax lets you deal with any IPC::Run
subclasses that might crop up, but don't hold your breath waiting for
any.

run() and finish() return TRUE when all subcommands exit with a 0 result
code.  B<This is the opposite of perl's system() command>.

All routines raise exceptions (via die()) when error conditions are
recognized.  A non-zero command result is not treated as an error
condition, since some commands are tests whose results are reported 
in their exit codes.

=head1 ROUTINES

=over

=cut

use strict ;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS $debug ) ;

use Exporter ;
use Fcntl ;
use POSIX () ;
use Symbol ;

$VERSION = '0.44' ;

@ISA = qw( Exporter ) ;

## We use @EXPORT for the end user's convenience: there's only one function
## exported, it's homonymous with the module, it's an unusual name, and
## it can be suppressed by "use IPC::Run () ;".

my @FILTER_IMP = qw( input_avail get_more_input ) ;
my @FILTERS    = qw(
   new_appender
   new_chunker
   new_string_source
   new_string_sink
) ;
my @API        = qw(
   run
   harness start pump finish
   io timer timeout
   close_terminal
) ;

@EXPORT_OK = ( @API, @FILTER_IMP, @FILTERS, qw( filter_tests ) ) ;
%EXPORT_TAGS = (
   'filter_imp' => \@FILTER_IMP,
   'all'        => \@EXPORT_OK,
   'filters'    => \@FILTERS,
   'api'        => \@API,
) ;

use Carp ;
use Errno qw( EAGAIN ) ;
use File::Spec ;
use IO::Handle ;
require IPC::Run::IO ;
require IPC::Run::Timer ;
use UNIVERSAL qw( isa ) ;

use fields (
   'IOS',          # Filehandles passed in by caller for us to watch, like
                   # PIPES except that we perform no management of these,
		   # just I/O.  These are encapsulated in IPC::Run::IO
		   # instances.

   'KIDS',         # Child processes

   'PIPES',        # Pipes & Pty handles to/from child procs
                   # These are references to entries in @{$_->{OPS}} for @KIDS

   'PTYS',         # A hash of pty nicknames => ( undef or IO::Pty instances ).
                   # Elts are undef until _open_pipes() and after _cleanup().

   'TIMERS',       # All timer / timeout objects

   'STATE',        # See constant subs immediately below.

   'TEMP_FILTERS', # These are filters installed by _open_pipes() and removed
                   # by _cleanup() to handle I/O to/from handles.

#   'TIMEOUT',      # Master timeout interval
#
#   'TIMEOUT_END',  # The end-time of the current timeout interval
#
   # Bit vectors for select()
   'RIN',
   'WIN',
   'EIN',
   'ROUT',
   'WOUT',
   'EOUT',
   'PIN',          # A bit vector holding paused PIPES that would otherwise
                   # be set in WIN.  This is a bit vector to make the
		   # debugging display of filehandles easier to build, since
		   # it can treat this just like EIN, WIN, and RIN.

   # Some options.  These get set by API entry subs and used by _internal
   # subs. 
   'auto_close_ins',
   'break_on_io',
   'clear_ins',
   'non_blocking',

   # Option flags, passed in by caller
   'debug',
#   'timeout',

   # Testing flags, passed in from t/*.t
   '_simulate_fork_failure',
   '_simulate_open_failure',
) ;

$debug = 0 ;

sub input_avail() ;
sub get_more_input() ;

###############################################################################

##
## State machine states, set in $self->{STATE}
##
## These must be in ascending order numerically
##
sub _newed()    {0}
sub _harnessed(){1}
sub _finished() {2}   ## _finished behave almost exactly like _harnessed
sub _started()  {3}

##
## Debugging routines
##
sub _map_fds {
   my $map = '' ;
   my $digit = 0 ;
   my $in_use ;
   for my $fd (0..63) {
      ## I'd like a quicker way (less user, cpu & expecially sys and kernal
      ## calls) to detect open file descriptors.  Let me know...
      my $test_fd = POSIX::dup( $fd ) ;
      $in_use = defined $test_fd ;
      POSIX::close $test_fd if $in_use ;
      $map .= $in_use ? $digit : '-';
      $digit = 0 if ++$digit > 9 ;
   }
   warn "No fds open???" unless $map =~ /1/ ;
   $map =~ s/(.{1,12})-*$/$1/ ;
   return $map ;
}


my $parent_pid = $$ ;

## We emit our debugging msgs on this fd.  It's changed in the kids so
## that the parent can catch them and emit them (in case kid's STDERR is
## redirected).
my $debug_fd = fileno STDERR ;

## Kids send to our select loop on this fd.
my $recv_debug_fd ;

sub _debug {
   return unless $debug ;

   my $s ;
   my $prefix = join(
      '',
      'IPC::Run',
      ( $$ eq $parent_pid ? () : ( '[', $$, ']' ) ),
      ': ',
      ( $debug > 2 ? ( _map_fds, ' ' ) : () ),
   ) ;

   my $msg = join( '', map defined $_ ? $_ : "<undef>", @_ ) ;
   chomp $msg ;
   $msg =~ s{^}{$prefix}gm ;
   $msg .= "\n" ;
   POSIX::write( $debug_fd, $msg, length $msg ) ;
}


my @fd_descs = ( 'stdin', 'stdout', 'stderr' ) ;

sub _debug_fd {
   return unless $debug ;
   my $text = shift ;
   my $op = pop ;
   my $kid = $_[0] ;

   _debug(
      $text,
      ' ',
      ( defined $op->{FD}
         ? $op->{FD} < 3
	    ? ( $fd_descs[$op->{FD}] )
	    : ( defined $recv_debug_fd && $op->{FD} eq $recv_debug_fd )
	       ? ( 'debug (', $op->{FD}, ')' )
	       : ( 'fd ', $op->{FD} )
	 : $op->{FD}
      ),
      ( defined $op->{KFD}
         ? (
	    ' (kid',
	    ( defined $kid ? ( ' ', $kid->{NUM}, ) : () ),
	    "'s ",
	    ( $op->{KFD} < 3
	       ? $fd_descs[$op->{KFD}]
	       : defined $kid
		  && defined $kid->{DEBUG_FD}
		  && $op->{KFD} == $kid->{DEBUG_FD}
		  ? ( 'debug (', $op->{KFD}, ')' )
		  : ( 'fd ', $op->{KFD} )
	    ),
	    ')',
	 )
	 : ()
      ),
   ) ;
}

##
## Support routines (NOT METHODS)
##
my %cmd_cache ;

sub _search_path {
   my ( $cmd_name ) = @_ ;
   if ( File::Spec->file_name_is_absolute( $cmd_name ) ) {
      _debug "'", $cmd_name, "' is absolute" ;
      return $cmd_name ;
   }

   my $dirsep =
      ( $^O =~ /^(?:MSWin32|dos|os2)$/
         ? '[/\\\\]'
      : $^O =~ /MacOS/
         ? ':'
      : $^O =~ /VMS/
         ? '[\[\]]'
      : '/'
      ) ;

   if ( $cmd_name =~ /($dirsep)/ ) {
      _debug "'", $cmd_name, "' contains '", $1, "'" ;
      return $cmd_name ;
   }

   if ( exists $cmd_cache{$cmd_name} ) {
      _debug "'", $cmd_name, "' found in cache: '", $cmd_cache{$cmd_name}, "'" ;
      return $cmd_cache{$cmd_name} if -x $cmd_cache{$cmd_name} ;
      _debug "'", $cmd_cache{$cmd_name},"' no longer executable, searching..." ;
   }

   my @searched_in ;

   unless ( exists $cmd_cache{$cmd_name} ) {
      ## This next bit is Unix specific, unfortunately.
      ## There's been some conversation about extending File::Spec to provide
      ## a universal interface to PATH, but I haven't seen it yet.
      my $re ;
      for ( $^O ) {
         if ( /Win32/ )         { $re = qr/;/ }
         else                   { $re = qr/:/ }
      }
   LOOP:
      for ( split( $re, $ENV{PATH}, -1 ) ) {
	 $_ = "." unless length $_ ;
	 push @searched_in, $_ ;

	 my $prospect = File::Spec->catfile( $_, $cmd_name ) ;
         my @prospects ;
         ## TODO: Use a better algorithm for finding executables on
         ## non-Unix.  Maybe defer to system().
         for ( $^O ) {
            if ( /Win32/ ) {
               @prospects = -f $prospect
                  ? ( $prospect )
                  : ( $prospect, glob( "$prospect.*" ) )  ;
            }
            else {
               @prospects = ( $prospect ) ;
            }
         }
         for my $found ( @prospects ) {
            if ( -f $found && -x _ ) {
	       _debug 'found ', $found ;
	       $cmd_cache{$cmd_name} = $found ;
	       last LOOP ;
	    }
         }
      }
   }
   if ( exists $cmd_cache{$cmd_name} ) {
      _debug "'", $cmd_name, "' added to cache: '", $cmd_cache{$cmd_name}, "'" ;
      return $cmd_cache{$cmd_name} ;
   }

   croak "Command '$cmd_name' not found in " . join( ", ", @searched_in ) ;
}


sub _empty($) { ! ( defined $_[0] && length $_[0] ) }

## 'safe' versions of otherwise fun things to do
sub _close {
   confess 'undef' unless defined $_[0] ;
   no strict 'refs' ;
   my $fn = $_[0] =~ /^\d+$/ ? $_[0] : fileno $_[0] ;
   my $r = POSIX::close $_[0] ;
   $r = $r ? '' : " ERROR $!" ;
   _debug "close( $fn )$r" if $debug > 2 ;
}

sub _dup {
   confess 'undef' unless defined $_[0] ;
   my $r = POSIX::dup( $_[0] ) ;
   croak "$!: dup( $_[0] )" unless defined $r ;
   $r = 0 if $r eq '0 but true' ;
   _debug "dup( $_[0] ) = $r" if $debug > 2 ;
   return $r ;
}


sub _dup2 {
   confess 'undef' unless defined $_[0] && defined $_[1] ;
   my $r = POSIX::dup2( $_[0], $_[1] ) ;
   croak "$!: dup2( $_[0], $_[1] )" unless defined $r ;
   $r = 0 if $r eq '0 but true' ;
   _debug "dup2( $_[0], $_[1] ) = $r" if $debug > 2 ;
   return $r ;
}

sub _exec {
   confess 'undef' unless defined $_[0] ;
   exec @_ or croak "$!: exec( " . join( ', ', @_ ) . " )" ;
}

sub _sysopen {
   confess 'undef' unless defined $_[0] && defined $_[1] ;
   my $r = POSIX::open( $_[0], $_[1], 0644 ) ;
   croak "$!: open( $_[0], $_[1] )" unless defined $r ;
   _debug "open( $_[0], $_[1] ) = $r" if $debug > 2 ;
   return $r ;
}

sub _pipe {
   my ( $r, $w ) = POSIX::pipe ;
   croak "$!: pipe()" unless $r ;
   _debug "pipe() = ( $r, $w ) " if $debug > 2 ;
   return ( $r, $w ) ;
}


sub _pty {
   require IO::Pty ;
   my $pty = IO::Pty->new() ;
   $pty->autoflush() ;
   croak "$!: pty ()" unless $pty ;
   _debug "pty() = ", $pty->fileno if $debug > 2 ;
   return $pty ;
}


sub _read {
   confess 'undef' unless defined $_[0] ;
   my $s  = '' ;
   my $r = POSIX::read( $_[0], $s, 100000 ) ;
   croak "$!: read( $_[0] )" unless $r ;
   _debug "read( $_[0] ) = '$s'" if $debug > 2 ;
   return $s ;
}


sub _write {
   confess 'undef' unless defined $_[0] && defined $_[1] ;
   my $r = POSIX::write( $_[0], $_[1], length $_[1] ) ;
   croak "$!: write( $_[0], '$_[1]' )" unless $r ;
   _debug "write( $_[0], '$_[1]' ) = $r" if $debug > 2 ;
   return $r ;
}


=item run

Run takes a harness or harness specification and runs it, pumping
all input to the child(ren), closing the input pipes when no more
input is available, collecting all output that arrives, until the
pipes delivering output are closed, then waiting for the children to
exit and reaping their result codes.

You may think of C<run( ... )> as being like 

   start( ... )->finish() ;

, though there is one subtle difference: run() does not
set \$input_scalars to '' like finish() does.

=cut

sub run {
   my IPC::Run $self = start( @_ ) ;
   $self->{clear_ins} = 0 ;
   $self->finish ;
}


=item harness

Takes a harness specification and returns a harness.  This harness is
blessed in to IPC::Run, allowing you to use method call syntax for
run(), start(), et al if you like.

harness() is provided so that you can pre-build harnesses if you
would like to, but it's not required..

You may proceed to run(), start() or pump() after calling harness() (pump()
calls start() if need be).  Alternatively, you may pass your
harness specification to run() or start() and let them harness() for
you.  You can't pass harness specifications to pump(), though.

=cut

##
## Notes: I've avoided handling a scalar that doesn't look like an
## opcode as a here document or as a filename, though I could DWIM
## those.  I'm not sure that the advantages outweight the danger when
## the DWIMer guesses wrong.
##
sub harness {
   my $options ;
   if ( @_ && ref $_[-1] eq 'HASH' ) {
      $options = pop ;
      require Data::Dumper ;
      carp "Passing in options as a hash is deprecated:\n", Data::Dumper::Dumper( $options ) ;
   }

   local $debug = $options->{debug} if $options && defined $options->{debug} ;

   my @args ;

   if ( @_ == 1 && ! ref $_[0] ) {
      my @shell ;
      for ( $^O ) {
         if ( /Win32/ )     { @shell = qw( command /c ) }
         else               { @shell = qw( sh -c      ) }
      }
      @args = ( [ @shell, @_ ] ) ;
   }
   elsif ( @_ > 1 && ! grep ref $_, @_ ) {
      @args = ( [ @_ ] ) ;
   }
   else {
      @args = @_ ;
   }

   my @errs ;               # Accum errors, emit them when done.

   my $succinct ;           # set if no redir ops are required yet.  Cleared
                            # if an op is seen.

   my $cur_kid ;            # references kid or handle being parsed

   my $assumed_fd    = 0 ;  # fd to assume in succinct mode (no redir ops)
   my $kid_num       = 0 ;  # 1... is which kid we're parsing
   my $handle_num    = 0 ;  # 1... is which handle we're parsing

   my IPC::Run $self ;
   {
      no strict 'refs' ;
      $self = bless [ \%{"FIELDS"} ], __PACKAGE__ ;
   }

   $self->{IOS}   = [] ;
   $self->{KIDS}  = [] ;
   $self->{PIPES} = [] ;
   $self->{PTYS}  = {} ;
   $self->{STATE} = _newed ;

   if ( $options ) {
      $self->{$_} = $options->{$_}
	 for keys %$options ;
   }

   _debug "** harnessing" ;

   my $first_parse ;
   local $_ ;
   my $arg_count = @args ;
   while ( @args ) { for ( shift @args ) {
      eval {
         $first_parse = 1 ;
         _debug(
	    "parsing ",
	    defined $_
	       ? ref $_ eq 'ARRAY'
	          ? ( '[ ', join( ', ', map "'$_'", @$_ ), ' ]' )
		  : ( ref $_
		     || ( length $_ < 10
			   ? "'$_'"
			   : join( '', "'", substr( $_, 0, 10 ), "...'" )
			)
		  )
	       : '<undef>'
	 ) if $debug > 1 ;

      REPARSE:
	 if ( ref eq 'ARRAY' || ( ! $cur_kid && ref eq 'CODE' ) ) {
	    croak "Process control symbol ('|', '&') missing" if $cur_kid ;
	    $cur_kid = {
	       TYPE => 'cmd',
	       VAL  => $_,
	       NUM  => ++$kid_num,
	       OPS  => [],
	       PID  => '',
	    } ;
	    push @{$self->{KIDS}}, $cur_kid ;
	    $succinct = 1 ;
	 }

	 elsif ( isa( $_, 'IPC::Run::IO' ) ) {
	    push @{$self->{IOS}}, $_ ;
	    $cur_kid = undef ;
	    $succinct = 1 ;
	 }
	 
	 elsif ( isa( $_, 'IPC::Run::Timer' ) ) {
	    push @{$self->{TIMERS}}, $_ ;
	    $cur_kid = undef ;
	    $succinct = 1 ;
	 }
	 
	 elsif ( /^(\d*)>&(\d+)$/ ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'dup',
	       KFD1 => $2,
	       KFD2 => length $1 ? $1 : 1,
	    } ;
	    _debug "redirect operators now required" if $debug > 1 ;
	    $succinct = ! $first_parse ;
	 }

	 elsif ( /^(\d*)<&(\d+)$/ ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'dup',
	       KFD1 => $2,
	       KFD2 => length $1 ? $1 : 0,
	    } ;
	    $succinct = ! $first_parse ;
	 }

	 elsif ( /^(\d*)<&-$/ ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'close',
	       KFD  => length $1 ? $1 : 0,
	    } ;
	    $succinct = ! $first_parse ;
	 }

	 elsif (
	       /^(\d*) (<pipe)()            ()  ()  $/x
	    || /^(\d*) (<pty) ((?:\s+\S+)?) (<) ()  $/x
	    || /^(\d*) (<)    ()            ()  (.*)$/x
	 ) {
	    croak "No command before '$_'" unless $cur_kid ;

	    $succinct = ! $first_parse ;

	    my $type = $2 . $4 ;

	    my $kfd = length $1 ? $1 : 0 ;

	    my $pty_id ;
	    if ( $type eq '<pty<' ) {
	       $pty_id = length $3 ? $3 : '0' ;
	       ## do the require here to cause early error reporting
	       require IO::Pty ;
	       ## Just flag the pyt's existence for now.  It'll be
	       ## converted to a real IO::Pty by _open_pipes.
	       $self->{PTYS}->{$pty_id} = undef ;
	    }

            my $source = $5 ;

	    my @filters ;

	    unless ( length $source ) {
	       if ( ! $succinct ) {
		  push @filters, shift @args
		     while @args > 1 && ref $args[1] ;
	       }
	       $source = shift @args ;
	       croak "'$_' missing a source" if _empty $source ;

	       _debug(
		  'Kid ', $cur_kid->{NUM}, "'s input fd ", $kfd,
		  ' has ', scalar( @filters ), ' filters.'
	       ) if $debug > 1 && @filters ;
	    } ;

	    my IPC::Run::IO $pipe = IPC::Run::IO->_new_internal(
	       $type, $kfd, $pty_id, $source, @filters
	    ) ;

	    if (  ( ref $source eq 'GLOB' || isa( $source, 'IO::Handle' ) )
	       && $type !~ /^<p(ty<|ipe)$/
	    ) {
	       $pipe->{DONT_CLOSE} = 1 ; ## this FD is not closed by us.
	    }

	    push @{$cur_kid->{OPS}}, $pipe ;
      }

	 elsif ( /^()   (>>?)  (&)     ()      (.*)$/x
	    ||   /^()   (&)    (>pipe) ()      ()  $/x 
	    ||   /^()   (>pipe)(&)     ()      ()  $/x 
	    ||   /^(\d*)()     (>pipe) ()      ()  $/x
	    ||   /^()   (&)    (>pty)  ( \w*)> ()  $/x 
## TODO:    ||   /^()   (>pty) (\d*)> (&) ()  $/x 
	    ||   /^(\d*)()     (>pty)  ( \w*)> ()  $/x
	    ||   /^()   (&)    (>>?)   ()      (.*)$/x 
	    ||   /^(\d*)()     (>>?)   ()      (.*)$/x
	 ) {
	    croak "No command before '$_'" unless $cur_kid ;

	    $succinct = ! $first_parse ;

	    my $type = (
	       $2 eq '>pipe' || $3 eq '>pipe'
	          ? '>pipe'
		  : $2 eq '>pty' || $3 eq '>pty'
		     ? '>pty>'
		     : '>'
	    ) ;
	    my $kfd = length $1 ? $1 : 1 ;
	    my $trunc = ! ( $2 eq '>>' || $3 eq '>>' ) ;
	    my $pty_id = (
	       $2 eq '>pty' || $3 eq '>pty'
	          ? length $4 ? $4 : 0
		  : undef
	    ) ;

	    my $stderr_too =
	          $2 eq '&'
	       || $3 eq '&'
	       || ( ! length $1 && substr( $type, 0, 4 ) eq '>pty' ) ;

            my $dest = $5 ;
	    my @filters ;
	    unless ( length $dest ) {
	       if ( ! $succinct ) {
		  ## unshift...shift: '>' filters source...sink left...right
		  unshift @filters, shift @args
		     while @args > 1 && ref $args[1] ;
	       }

	       $dest = shift @args ;

	       _debug(
		  'Kid ', $cur_kid->{NUM}, "'s output fd ", $kfd,
		  ' has ', scalar( @filters ), ' filters.'
	       ) if $debug > 1 && @filters ;

	       if ( $type eq '>pty>' ) {
		  ## do the require here to cause early error reporting
		  require IO::Pty ;
		  ## Just flag the pyt's existence for now.  _open_pipes()
		  ## will new an IO::Pty for each key.
		  $self->{PTYS}->{$pty_id} = undef ;
	       }
	    }

	    croak "'$_' missing a destination" if _empty $dest ;
	    my $pipe = IPC::Run::IO->_new_internal(
	       $type, $kfd, $pty_id, $dest, @filters
	    ) ;
	    $pipe->{TRUNC} = $trunc ;

	    if (  ( isa( $dest, 'GLOB' ) || isa( $dest, 'IO::Handle' ) )
	       && $type !~ /^>(pty>|pipe)$/
	    ) {
	       $pipe->{DONT_CLOSE} = 1 ; ## this FD is not closed by us.
	    }
	    push @{$cur_kid->{OPS}}, $pipe ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'dup',
	       KFD1 => 1,
	       KFD2 => 2,
	    } if $stderr_too ;
	 }

	 elsif ( /^\|$/ ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    unshift @{$cur_kid->{OPS}}, {
	       TYPE => '|',
	       KFD  => 1,
	    } ;
	    $succinct   = 1 ;
            $assumed_fd = 1 ;
	    $cur_kid    = undef ;
	 }

	 elsif ( /^&$/ ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    unshift @{$cur_kid->{OPS}}, {
	       TYPE => 'close',
	       KFD  => 0,
	    } ;
	    $succinct   = 1 ;
            $assumed_fd = 0 ;
	    $cur_kid    = undef ;
	 }

	 elsif ( $_ eq 'init' ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'init',
	       SUB  => shift @args,
	    } ;
	 }

	 elsif ( ! ref $_ ) {
            my $opt = $_ ;
            croak "Illegal option '$_'"
               unless grep $_ eq $opt, keys %$self ; 
	    $self->{$_} = shift @args ;
	 }

	 elsif ( $_ eq 'init' ) {
	    croak "No command before '$_'" unless $cur_kid ;
	    push @{$cur_kid->{OPS}}, {
	       TYPE => 'init',
	       SUB  => shift @args,
	    } ;
	 }

	 elsif ( $succinct && $first_parse ) {
	    ## It's not an opcode, and no explicit opcodes have been
	    ## seen yet, so assume it's a file name.
	    unshift @args, $_ ;
	    if ( ! $assumed_fd ) {
	       $_ = "$assumed_fd<",
	    }
	    else {
	       $_ = "$assumed_fd>",
	    }
	    _debug "assuming '", $_, "'" if $debug > 1 ;
	    ++$assumed_fd ;
	    $first_parse = 0 ;
	    goto REPARSE ;
	 }

	 else {
	    croak join( 
	       '',
	       'Unexpected ',
	       ( ref() ? $_ : 'scalar' ),
	       ' in harness() parameter ',
	       $arg_count - @args
	    ) ;
	 }
      } ;
      if ( $@ ) {
	 push @errs, $@ ;
	 _debug 'caught ', $@ ;
      }
   } }

   die join( '', @errs ) if @errs ;


   $self->{STATE} = _harnessed ;
#   $self->timeout( $options->{timeout} ) if exists $options->{timeout} ;
   return $self ;
}


sub _open_pipes {
   my IPC::Run $self = shift ;

   my @errs ;

   my @close_on_fail ;

   ## When a pipe character is seen, a pipe is created.  $pipe_read_fd holds
   ## the read end of the pipe for the next process.
   my $pipe_read_fd ;

   ## Output descriptors for the last command are shared by all children.
   ## @output_fds_accum accumulates the current set of output fds.
   my @output_fds_accum ;

   for ( sort keys %{$self->{PTYS}} ) {
      _debug "opening pty '", $_, "'" if $debug > 2 ;
      my $pty = _pty ;
      $self->{PTYS}->{$_} = $pty ;
   }

   for ( @{$self->{IOS}} ) {
      eval { $_->init ; } ;
      if ( $@ ) {
	 push @errs, $@ ;
	 _debug 'caught ', $@ ;
      }
      else {
	 push @close_on_fail, $_ ;
      }
   }

   ## Loop through the kids and their OPS, interpreting any that require
   ## parent-side actions.
   for my $kid ( @{$self->{KIDS}} ) {
      unless ( ref $kid->{VAL} eq 'CODE' ) {
	 $kid->{PATH} = _search_path( $kid->{VAL}->[0] ) ;
      }
      if ( defined $pipe_read_fd ) {
	 unshift @{$kid->{OPS}}, {
	    TYPE => 'pipe',
	    KFD  => 0,
	    TFD  => $pipe_read_fd,
	 } ;
	 $pipe_read_fd = undef ;
      }
      @output_fds_accum = () ;
      for my $op ( @{$kid->{OPS}} ) {
	 eval {
	    if ( $op->{TYPE} eq '<' ) {
	       for my $source ( $op->{SOURCE} ) {
	          if ( ! ref $source ) {
		     _debug(
			"kid ", $kid->{NUM}, " to read ", $op->{KFD},
			" from '" .  $source, "' (read only)"
		     ) if $debug > 1 ;
		     croak "simulated open failure"
			if $self->{_simulate_open_failure} ;
		     $op->{TFD} = _sysopen( $source, O_RDONLY ) ;
		     push @close_on_fail, $op->{TFD} ;
		  }
		  elsif ( isa( $source, 'GLOB' )
		     ||   isa( $source, 'IO::Handle' )
		  ) {
		     croak
		        "Unopened filehandle in input redirect for $op->{KFD}"
		        unless defined fileno $source ;
		     $op->{TFD} = fileno $source ;
		     _debug(
		        "kid ", $kid->{NUM}, " to read ", $op->{KFD},
			" from fd ", $op->{TFD}
		     ) if $debug > 1 ;
		  }
		  elsif ( isa( $source, 'SCALAR' ) ) {
		     _debug(
		        "kid ", $kid->{NUM}, " to read ", $op->{KFD},
			" from SCALAR"
		     ) if $debug > 2 ;

                     ( $op->{TFD}, $op->{FD} ) = _pipe ;
		     push @close_on_fail, $op->{KFD}, $op->{FD} ;

		     my $s = '' ;
		     $op->{KIN_REF} = \$s ;
		  }
		  elsif ( isa( $source, 'CODE' ) ) {
		     _debug(
		     'kid ', $kid->{NUM}, ' to read ', $op->{KFD}, ' from CODE'
		     ) if $debug > 1 ;
		     ( $op->{TFD}, $op->{FD} ) = _pipe ;
		     push @close_on_fail, $op->{KFD}, $op->{FD} ;
		     my $s = '' ;
		     $op->{KIN_REF} = \$s ;
		  }
		  else {
		     croak(
		        "'"
			. ref( $source )
			. "' not allowed as a source for input redirection"
		     ) ;
		  }
	       }
	       $op->_init_filters ;
	    }
	    elsif ( $op->{TYPE} eq '<pipe' ) {
	       _debug(
		  'kid to read ', $op->{KFD},
		  ' from a pipe harness() opens and returns',
	       ) if $debug > 1 ;
	       my ( $r, $w ) = _pipe() ;
	       open( $op->{SOURCE}, ">&=$w" )
		  or croak "$! on write end of pipe" ;

	       $op->{TFD}    = $r ;
	       $op->_init_filters ;
	    }
	    elsif ( $op->{TYPE} eq '<pty<' ) {
	       _debug(
		  'kid to read ', $op->{KFD}, " from pty '", $op->{PTY_ID}, "'",
	       ) if $debug > 1 ;
	       
	       for my $source ( $op->{SOURCE} ) {
		  if ( isa( $source, 'SCALAR' ) ) {
		     _debug(
			"kid ", $kid->{NUM}, " to read ", $op->{KFD},
			" from SCALAR via pty '", $op->{PTY_ID}, "'"
		     ) if $debug > 1 ;

		     my $s = '' ;
		     $op->{KIN_REF} = \$s ;
		  }
		  elsif ( isa( $source, 'CODE' ) ) {
		     _debug(
			"kid ", $kid->{NUM}, " to read ", $op->{KFD},
			" from CODE via pty '", $op->{PTY_ID}, "'"
		     ) if $debug > 1 ;
		     my $s = '' ;
		     $op->{KIN_REF} = \$s ;
		  }
		  else {
		     croak(
			"'"
			. ref( $source )
			. "' not allowed as a source for '<pty<'redirection"
		     ) ;
		  }
	       }
	       $op->{FD} = $self->{PTYS}->{$op->{PTY_ID}}->fileno ;
	       $op->{TFD} = undef ; # The fd isn't known until after fork().
	       $op->_init_filters ;
	    }
	    elsif ( $op->{TYPE} eq '>' ) {
	       ## N> output redirection.
	       my $dest = $op->{DEST} ;
	       if ( ! ref $dest ) {
		  _debug(
		     "kid ", $kid->{NUM}, " to write ", $op->{KFD},
		     " to '", $dest, "' (write only, create, ",
		     ( $op->{TRUNC} ? 'truncate' : 'append' ),
		     ")"
		  ) if $debug > 1 ;
		  croak "simulated open failure"
		     if $self->{_simulate_open_failure} ;
		  $op->{TFD} = _sysopen(
		     $dest,
		     ( O_WRONLY
		     | O_CREAT 
		     | ( $op->{TRUNC} ? O_TRUNC : O_APPEND )
		     )
		  ) ;
		  push @close_on_fail, $op->{TFD} ;
	       }
	       elsif ( isa( $dest, 'GLOB' ) ) {
		  croak(
		   "Unopened filehandle in output redirect, command $kid->{NUM}"
		  ) unless defined fileno $dest ;
		  ## Turn on autoflush, mostly just to flush out
		  ## existing output.
		  my $old_fh = select( $dest ) ; $| = 1 ; select( $old_fh ) ;
		  $op->{TFD} = fileno $dest ;
		  _debug(
		     'kid to write ', $op->{KFD}, ' to handle ', $op->{TFD}
		  ) if $debug > 1 ;
	       }
	       elsif ( isa( $dest, 'SCALAR' ) ) {
		  _debug(
		     "kid ", $kid->{NUM}, " to write $op->{KFD} to SCALAR"
		  ) if $debug > 1 ;

		  ( $op->{FD}, $op->{TFD} ) = _pipe ;
		  push @close_on_fail, $op->{FD}, $op->{TFD} ;
		  $$dest = '' if $op->{TRUNC} ;
	       }
	       elsif ( isa( $dest, 'CODE' ) ) {
		  _debug(
		     "kid $kid->{NUM} to write $op->{KFD} to CODE"
		  ) if $debug > 1 ;
		  ( $op->{FD}, $op->{TFD} ) = _pipe ;
		  push @close_on_fail, $op->{FD}, $op->{TFD} ;
	       }
	       else {
		  croak(
		     "'"
		     . ref( $dest )
		     . "' not allowed as a sink for output redirection"
		  ) ;
	       }
	       $output_fds_accum[$op->{KFD}] = $op ;
	       $op->_init_filters ;
	    }

	    elsif ( $op->{TYPE} eq '>pipe' ) {
	       ## N> output redirection to a pipe we open, but don't select()
	       ## on.
	       _debug(
		  "kid ", $kid->{NUM}, " to write ", $op->{KFD},
		  ' to a pipe harness() returns'
	       ) if $debug > 1 ;
	       my ( $r, $w ) = _pipe() ;
	       open( $op->{DEST}, "<&=$r" )
		  or croak "$! duping read end of pipe" ;
	       $op->{TFD} = $w ;
	       $output_fds_accum[$op->{KFD}] = $op ;
	       $op->_init_filters ;
	    }
	    elsif ( $op->{TYPE} eq '>pty>' ) {
	       my $dest = $op->{DEST} ;
	       if ( isa( $dest, 'SCALAR' ) ) {
		  _debug(
		     "kid ", $kid->{NUM}, " to write ", $op->{KFD},
		     " to SCALAR via pty '", $op->{PTY_ID}, "'"
	       ) if $debug > 1 ;

		  $$dest = '' if $op->{TRUNC} ;
	       }
	       elsif ( isa( $dest, 'CODE' ) ) {
		  _debug(
		     "kid ", $kid->{NUM}, " to write ", $op->{KFD},
		     " to CODE via pty '", $op->{PTY_ID}, "'"
		  ) if $debug > 1 ;
	       }
	       else {
		  croak(
		     "'"
		     . ref( $dest )
		     . "' not allowed as a sink for output redirection"
		  ) ;
	       }

	       $op->{FD} = $self->{PTYS}->{$op->{PTY_ID}}->fileno ;
	       $op->{TFD} = undef ; # The fd isn't known until after fork().
	       $output_fds_accum[$op->{KFD}] = $op ;
	       $op->_init_filters ;
	    }
	    elsif ( $op->{TYPE} eq '|' ) {
	       _debug(
	          "pipelining $kid->{NUM} and "
	          . ( $kid->{NUM} + 1 )
	       ) if $debug > 1 ;
	       ( $pipe_read_fd, $op->{TFD} ) = _pipe ;
	       @output_fds_accum = () ;
	    }
	    elsif ( $op->{TYPE} eq '&' ) {
	       @output_fds_accum = () ;
	    } # end if $op->{TYPE} tree
	 } # end for ( OPS }
      } ; # end eval
      if ( $@ ) {
      die ;
	 push @errs, $@ ;
	 _debug 'caught ', $@ ;
      }
   } # end for ( KIDS )
   if ( @errs ) {
      for ( @close_on_fail ) {
	 _close( $_ ) ;
	 $_ = undef ;
      }
      for ( keys %{$self->{PTYS}} ) {
	 next unless $self->{PTYS}->{$_} ;
         close $self->{PTYS}->{$_} ;
         $self->{PTYS}->{$_} = undef ;
      }
      die join( '', @errs )
   }

   ## give all but the last child all of the output file descriptors
   ## These will be reopened (and thus rendered useless) if the child
   ## dup2s on to these descriptors, since we unshift these.
   for ( my $num = 0 ; $num < $#{$self->{KIDS}} ; ++$num ) {
      for ( reverse @output_fds_accum ) {
         next unless defined $_ ;
	 _debug(
	    'kid ', $self->{KIDS}->[$num]->{NUM}, ' also to write ', $_->{KFD},
	    ' to ', ref $_->{DEST}
	 ) if $debug > 1 ;
	 unshift @{$self->{KIDS}->[$num]->{OPS}}, $_ ;
      }
   }

   ## Open the debug pipe if we need it
   my $w_debug_fd = -1 ;
   $debug_fd = fileno STDERR ;
   $recv_debug_fd = undef ;

   if ( $debug && @{$self->{KIDS}} ) {
      _debug "creating debug pipe" if $debug > 1 ;
      ( $recv_debug_fd, $w_debug_fd ) = _pipe ;
      for my $kid ( @{$self->{KIDS}} ) {
         ## We unshift this so it will be first in @files.  This makes the
	 ## kids' debugging output get printed before ours does on a given
	 ## select() call.
         unshift @{$kid->{OPS}}, {
	    TYPE => '>',
	    TFD  => $w_debug_fd,
	    KFD  => $w_debug_fd,
	    FD   => $recv_debug_fd,
	    IS_DEBUG => 1,
	 } if defined $recv_debug_fd ;
	 $kid->{DEBUG_FD} = $w_debug_fd ;
      }
   }

   ## Create the list of PIPES we need to scan and the bit vectors needed by
   ## select().  Do this first so that _cleanup can _clobber() them if an
   ## exception occurs.
   @{$self->{PIPES}} = () ;
   $self->{RIN} = '' ;
   $self->{WIN} = '' ;
   $self->{EIN} = '' ;
   ## PIN is a vec()tor that indicates who's paused.
   $self->{PIN} = '' ;
   for my $kid ( @{$self->{KIDS}} ) {
      for ( @{$kid->{OPS}} ) {
	 if ( defined $_->{FD} ) {
	    _debug(
	       'kid ', $kid->{NUM}, '[', $kid->{PID}, "]'s ", $_->{KFD},
	       ' is my ', $_->{FD}
	    ) if $debug > 1 ;
	    vec( $self->{ $_->{TYPE} =~ /^</ ? 'WIN' : 'RIN' }, $_->{FD}, 1 )=1;
#	    vec( $self->{EIN}, $_->{FD}, 1 ) = 1 ;
	    push @{$self->{PIPES}}, $_ ;
	 }
      }
   }

   for my $io ( @{$self->{IOS}} ) {
      my $fd = $io->fileno ;
      vec( $self->{RIN}, $fd, 1 ) = 1 if $io->mode =~ /r/ ;
      vec( $self->{WIN}, $fd, 1 ) = 1 if $io->mode =~ /w/ ;
#      vec( $self->{EIN}, $fd, 1 ) = 1 ;
      push @{$self->{PIPES}}, $io ;
   }

   ## Put filters on the end of the filter chains to read & write the pipes.
   ## Clear pipe states
   for my $pipe ( @{$self->{PIPES}} ) {
      $pipe->{SOURCE_EMPTY} = 0 ;
      $pipe->{PAUSED} = 0 ;
      if ( $pipe->{TYPE} =~ /^>/ ) {
	 my $pipe_reader = sub {
	    my ( undef, $out_ref ) = @_ ;

	    return undef unless defined $pipe->{FD} ;
	    return 0 unless vec( $self->{ROUT}, $pipe->{FD}, 1 ) ;

	    vec( $self->{ROUT}, $pipe->{FD}, 1 ) = 0 ;

	    _debug_fd( 'reading from', $pipe ) if $debug > 2 ;
	    my $in = eval { _read( $pipe->{FD} ) } ;
	    if ( $@ ) {
	       $in = '' ;
	       ## IO::Pty throws this if the kid dies.
	       die $@ unless $@ =~ /^Input\/output error: read/ ;
	    }

	    unless ( length $in ) {
	       $self->_clobber( $pipe ) ;
	       return undef ;
	    }

	    $$out_ref .= $in ;
	    return 1 ;
	 } ;
	 ## Input filters are the last filters
	 push @{$pipe->{FILTERS}}, $pipe_reader ;
	 push @{$self->{TEMP_FILTERS}}, $pipe_reader ;
      }
      else {
	 my $pipe_writer = sub {
	    my ( $in_ref, $out_ref ) = @_ ;
	    return undef unless defined $pipe->{FD} ;
	    return 0
	       unless vec( $self->{WOUT}, $pipe->{FD}, 1 )
		  || $pipe->{PAUSED} ;

	    vec( $self->{WOUT}, $pipe->{FD}, 1 ) = 0 ;

	    if ( ! length $$in_ref ) {
	       if ( ! defined get_more_input ) {
		  $self->_clobber( $pipe ) ;
		  return undef ;
	       }
	    }

	    unless ( length $$in_ref ) {
	       unless ( $pipe->{PAUSED} ) {
		  _debug_fd( 'pausing', $pipe ) if $debug > 2 ;
		  vec( $self->{WIN}, $pipe->{FD}, 1 ) = 0 ;
#		  vec( $self->{EIN}, $pipe->{FD}, 1 ) = 0 ;
		  vec( $self->{PIN}, $pipe->{FD}, 1 ) = 1 ;
		  $pipe->{PAUSED} = 1 ;
	       }
	       return 0 ;
	    }
	    _debug_fd( 'writing to', $pipe ) if $debug > 2 ;

	    my $c = _write( $pipe->{FD}, $$in_ref ) ;
	    substr( $$in_ref, 0, $c, '' ) ;
	    return 1 ;
	 } ;
	 ## Output filters are the first filters
	 unshift @{$pipe->{FILTERS}}, $pipe_writer ;
	 push    @{$self->{TEMP_FILTERS}}, $pipe_writer ;
      }
   }
}


sub _dup2_gently {
   my ( $files, $fd1, $fd2 ) = @_ ;
   ## Moves TFDs that are using the destination fd out of the
   ## way before calling _dup2
   for ( @$files ) {
      next unless defined $_->{TFD} ;
      $_->{TFD} = _dup( $_->{TFD} ) if $_->{TFD} == $fd2 ;
   }
   _dup2( $fd1, $fd2 ) ;
}

=item close_terminal

This is used as (or in) an init sub to cast off the bonds of a controlling
terminal.  It must precede all other redirection ops that affect
STDIN, STDOUT, or STDERR to be guaranteed effective.

=cut


sub close_terminal {
   ## Cast of the bonds of a controlling terminal
   POSIX::setsid() || croak "POSIX::setsid() failed" ;
   _debug "closing stdin, out, err" ;
   close STDIN ;
   close STDERR ;
   close STDOUT ;
}


sub _do_kid {
   my IPC::Run $self = shift ;
   my ( $kid ) = @_ ;

   $debug_fd = $kid->{DEBUG_FD} ;
   ## close parent FD's first so they're out of the way.
   ## Don't close STDIN, STDOUT, STDERR: they should be inherited or
   ## overwritten below.
   my @needed = ( 1, 1, 1 ) ;

   for ( @{$kid->{OPS}} ) {
      $needed[ $_->{TFD} ] = 1 if defined $_->{TFD} ;
   }

   my @closed ;
   if ( %{$self->{PTYS}} ) {
      ## Clean up the parent's fds.
      for ( keys %{$self->{PTYS}} ) {
	 _debug "Cleaning up parent's ptty '$_'" if $debug > 1 ;
	 my $slave = $self->{PTYS}->{$_}->slave ;
	 $closed[ $self->{PTYS}->{$_}->fileno ] = 1 ;
	 close $self->{PTYS}->{$_} ;
	 $self->{PTYS}->{$_} = $slave ;
      }

      close_terminal ;
      $closed[ $_ ] = 1 for ( 0..2 ) ;
   }

   for my $sibling ( @{$self->{KIDS}} ) {
      for ( @{$sibling->{OPS}} ) {
	 if ( $_->{TYPE} =~ /^.pty.$/ ) {
	    $_->{TFD} = $self->{PTYS}->{$_->{PTY_ID}}->fileno ;
	    $needed[$_->{TFD}] = 1 ;
	 }

         for ( $_->{FD}, ( $sibling != $kid ? $_->{TFD} : () ) ) {
	    if ( defined $_ && ! $closed[$_] && ! $needed[$_] ) {
	       _close( $_ ) ;
	       $closed[$_] = 1 ;
	       $_ = undef ;
	    }
         }
      }
   }

   my @lazy_close ;
   for ( @{$kid->{OPS}} ) {
      if ( defined $_->{TFD} ) {
	 unless ( $_->{TFD} == $_->{KFD} ) {
	    _dup2_gently( $kid->{OPS}, $_->{TFD}, $_->{KFD} ) ;
	    push @lazy_close, $_->{TFD} ;
	 }
      }
      elsif ( $_->{TYPE} eq 'dup' ) {
	 _dup2_gently( $kid->{OPS}, $_->{KFD1}, $_->{KFD2} )
	    unless $_->{KFD1} == $_->{KFD2} ;
      }
      elsif ( $_->{TYPE} eq 'close' ) {
         for ( $_->{KFD} ) {
	    if ( ! $closed[$_] ) {
	       _close( $_ ) ;
	       $closed[$_] = 1 ;
	       $_ = undef ;
	    }
	 }
      }
      elsif ( $_->{TYPE} eq 'init' ) {
         $_->{SUB}->() ;
      }
   }

   for ( @lazy_close ) {
      unless ( $closed[$_] ) {
	 _close( $_ ) ;
	 $closed[$_] = 1 ;
      }
   }

   if ( ref $kid->{VAL} eq 'CODE' ) {
      $kid->{VAL}->() ;
      exit 0 ;
   }
   else {
      _debug 'execing ', $kid->{PATH} ;
      POSIX::close( $debug_fd ) if defined $debug_fd ;
      _exec( $kid->{PATH}, @{$kid->{VAL}}[1..$#{$kid->{VAL}}] ) ;
      croak "exec of $kid->{PATH} failed $!" ;
   }
}


=item start

   $h = start(
      \@cmd, \$in, \$out, ...,
      timeout( 30, name => "process timeout" ),
      $stall_timeout = timeout( 10, name => "stall timeout"   ),
   ) ;

   $h = start \@cmd, '<', \$in, '|', \@cmd2, ... ;

start() accepts a harness or harness specification and returns a harness
after building all of the pipes and launching (via fork()/exec(), or, maybe
someday, spawn()) all the child processes.  It does not send or receive any
data on the pipes, see pump() and finish() for that.

You may call harness() and then pass it's result to start() if you like,
but you only need to if it helps you structure or tune your application.
If you do call harness(), you may skip start() and proceed directly to
pump.

start() also starts all timers in the harness.  See L<IPC::Run::Timer>
for more information.

start() flushes STDOUT and STDERR to help you avoid duplicate output.
It has no way of asking Perl to flush all your open filehandles, so
you are going to need to flush any others you have open.  Sorry.

Here's how if you don't want to alter the state of $| for your
filehandle:

   $ofh = select HANDLE ; $of = $| ; $| = 1 ; $| = $of ; select $ofh;

If you don't mind leaving output unbuffered on HANDLE, you can do
the slightly shorter

   $ofh = select HANDLE ; $| = 1 ; select $ofh;

Or, you can use IO::Handle's flush() method:

   use IO::Handle ;
   flush HANDLE ;

Perl needs the equivalent of C's fflush( (FILE *)NULL ).

=cut

sub start {
   my $options ;
   if ( @_ && ref $_[-1] eq 'HASH' ) {
      $options = pop ;
      require Data::Dumper ;
      carp "Passing in options as a hash is deprecated:\n", Data::Dumper::Dumper( $options ) ;
   }
   local $debug = $options->{debug} if $options && defined $options->{debug} ;

   my IPC::Run $self ;
   if ( @_ == 1 && isa( $_[0], __PACKAGE__ ) ) {
      $self = shift ;
      $self->{$_} = $options->{$_} for keys %$options ;
   }
   else {
      $self = harness( @_, $options ? $options : () ) ;
   }

   local $debug = $self->{debug} if defined $self->{debug} ;
   _debug "** starting" ;

   ## Assume we're not being called from &run.  It will correct our
   ## assumption if need be.  This affects whether &_select_loop clears
   ## input queues to '' when they're empty.
   $self->{clear_ins} = 1 ;

   my @errs ;

   for ( @{$self->{TIMERS}} ) {
      eval { $_->start } ;
      if ( $@ ) {
	 push @errs, $@ ;
	 _debug 'caught ', $@ ;
      }
   }

   eval { $self->_open_pipes } ;
   if ( $@ ) {
      push @errs, $@ ;
      _debug 'caught ', $@ ;
   }

## This is a bit of a hack, we should do it for all open filehandles.
## Since there's no way I know of to enumerate open filehandles, we simply
## autoflush STDOUT and STDERR.  This is done so that the children don't
## inherit output buffers chock full o' redundant data.  It's really
## confusing to track that down.
   {
      my $ofh = select STDOUT ; my $of = $| ; $| = 1 ; $| = $of ; select $ofh;
         $ofh = select STDERR ;    $of = $| ; $| = 1 ; $| = $of ; select $ofh;
   }
   if ( ! @errs ) {
      for my $kid ( @{$self->{KIDS}} ) {
	 eval {
	    croak "simulated failure of fork"
	       if $self->{_simulate_fork_failure} ;
	    unless ( $^O =~ /^(?:os2|MSWin32)$/ ) {
	       $kid->{PID} = fork() ;
	       $self->_do_kid( $kid ) unless $kid->{PID} ;
	       croak "$! during fork" unless defined $kid->{PID} ;
	       _debug "fork() = ", $kid->{PID} ;
	    }
	    else {
## TODO: Test and debug spawing code.  Someday.
	       _debug( 
		  'spawning ',
		  join(
		     ' ',
		     map(
			"'$_'",
			( $kid->{PATH}, @{$kid->{VAL}}[1..$#{$kid->{VAL}}] )
		     )
		  )
	       ) ;
	       require IPC::Open3 ;
	       require IO::Handle ;
	       my @close_in_kid ;
	       my $op ;

	       my @needed = (1,1,1) ;
	       for $op ( @{$kid->{OPS}} ) {
		  $needed[$op->{TFD}] = 1 if defined $op->{TFD}
	       }

	       for my $k ( @{$self->{KIDS}} ) {
		  for $op ( @{$k->{OPS}} ) {
		     my $mode = $op->{TYPE} =~ /^>/ ? 'w' : 'r' ;
		     for ( $op->{FD}, ( $k != $kid ? $_->{TFD} : () ) ) {
			push @close_in_kid, IO::Handle->new_from_fd( $_, $mode )
			   if defined $_ && ! $needed[ $_ ] ;
		     }
		  }
	       }

	       my @handle_map ;
	       for $op ( @{$kid->{OPS}} ) {
		  my $mode = $op->{TYPE} =~ /^>/ ? 'w' : 'r' ;
		  push @handle_map, {
		     mode    => $mode,
		     open_as => IO::Handle->new_from_fd( $op->{KFD}, $mode ),
		     handle  => IO::Handle->new_from_fd( $op->{TFD}, $mode ),
		  } if defined $op->{TFD} ;
	       }
	       $kid->{PID} = IPC::Open3::spawn_with_handles(
		  \@handle_map,
		  \@close_in_kid,
		  $kid->{PATH},
		  @{$kid->{VAL}}[1..$#{$kid->{VAL}}]
	       ) ;
	       _debug "spawn_with_handles() = ", $kid->{PID} ;
	    }
	 } ;
	 if ( $@ ) {
	    push @errs, $@ ;
	    _debug 'caught ', $@ ;
	 }
      }
   }

   ## Close all those temporary filehandles that the kids needed.
   my @closed ;
   for my $kid ( @{$self->{KIDS}} ) {
      for ( @{$kid->{OPS}} ) {
	 my $close_it = eval {
	    defined $_->{TFD}
	       && ! $_->{DONT_CLOSE}
	       && ! $closed[$_->{TFD}]
	 } ;
	 if ( $@ ) {
	    push @errs, $@ ;
	    _debug 'caught ', $@ ;
	 }
	 if ( $close_it || $@ ) {
	    eval {
	       _close( $_->{TFD} ) ;
	       $closed[$_->{TFD}] = 1 ;
	       $_->{TFD} = undef ;
	    } ;
	    if ( $@ ) {
	       push @errs, $@ ;
	       _debug 'caught ', $@ ;
	    }
	 }
      }
   }
confess "gak!" unless defined $self->{PIPES} ;

   if ( @errs ) {
      eval { $self->_cleanup } ;
      warn $@ if $@ ;
      die join( '', @errs ) ;
   }

   $self->{STATE} = _started ;
   return $self ;
}


sub _clobber {
   my IPC::Run $self = shift ;
   my ( $file ) = @_ ;
   _debug_fd( "closing", $file ) ;
   my $doomed = $file->{FD} ;
   my $dir = $file->{TYPE} =~ /^</ ? 'WIN' : 'RIN' ;
   vec( $self->{$dir}, $doomed, 1 ) = 0 ;
#   vec( $self->{EIN},  $doomed, 1 ) = 0 ;
   vec( $self->{PIN},  $doomed, 1 ) = 0 ;
   if ( $file->{TYPE} =~ /^(.)pty.$/ ) {
      if ( $1 eq '>' ) {
         ## Only close output ptys.  This is so that ptys as inputs are
	 ## never autoclosed, which would risk losing data that was
	 ## in the slave->parent queue.
	 _debug_fd "closing pty", $file ;
	 close $self->{PTYS}->{$file->{PTY_ID}}
	    if defined $self->{PTYS}->{$file->{PTY_ID}} ;
	 $self->{PTYS}->{$file->{PTY_ID}} = undef ;
      }
   }
   elsif ( isa( $file, 'IPC::Run::IO' ) ) {
      $file->close unless $file->{DONT_CLOSE} ;
   }
   else {
      _close( $doomed ) ;
   }
   @{$self->{PIPES}} = grep
      defined $_->{FD} && ( $_->{TYPE} ne $file->{TYPE} || $_->{FD} ne $doomed),
   @{$self->{PIPES}} ;
   $file->{FD} = undef ;
}


sub _select_loop {
   my IPC::Run $self = shift ;

   my $timeout = $self->{non_blocking} ? 0 : undef ;

   my $io_occurred ;

   croak "process ended prematurely" unless @{$self->{PIPES}} ;

SELECT:
   while ( @{$self->{PIPES}} ) {
      last if $io_occurred && $self->{break_on_io} ;

      if ( @{$self->{TIMERS}} ) {
	 my $now = time ;
	 my $time_left ;
	 for ( @{$self->{TIMERS}} ) {
	    next unless $_->is_running ;
	    $time_left = $_->check( $now ) ;
	    ## Return when a timer expires
	    return if defined $time_left && ! $time_left ;
	    $timeout = $time_left
	       if ! defined $timeout || $time_left < $timeout ;
	 }
      }
#      if ( defined $self->{TIMEOUT_END} ) {
#	 die "process timed out" if $now >= $self->{TIMEOUT_END} ;
#	 my $delta = $self->{TIMEOUT_END} - $now ;
#	 $timeout = $delta if ! defined $timeout || $timeout > $delta ;
#      }

      ##
      ## See if we can unpause any input channels
      ##
      my $paused = 0 ;

      for my $file ( @{$self->{PIPES}} ) {
         next unless $file->{PAUSED} && $file->{TYPE} =~ /^</ ;

	 _debug_fd( "checking", $file ) if $debug > 2 ;
	 my $did ;
	 1 while $did = $file->_do_filters( $self ) ;
	 if ( defined $file->{FD} && ! defined( $did ) || $did ) {
	    _debug_fd( "unpausing", $file ) if $debug > 1 ;
	    $file->{PAUSED} = 0 ;
	    vec( $self->{WIN}, $file->{FD}, 1 ) = 1 ;
#	    vec( $self->{EIN}, $file->{FD}, 1 ) = 1 ;
	    vec( $self->{PIN}, $file->{FD}, 1 ) = 0 ;
	 }
	 else {
	    ++$paused ;
	 }
      }

      ## _do_filters may have closed our last fd.
      last unless @{$self->{PIPES}} ;

      if ( $debug > 2 ) {
         my $map = join(
	    '',
	    map {
	       my $out ;
	       $out = 'r' if vec( $self->{RIN}, $_, 1 ) ;
	       $out = $out ? 'b' : 'w' if vec( $self->{WIN}, $_, 1 ) ;
	       $out = 'p' if ! $out && vec( $self->{PIN}, $_, 1 ) ;
	       $out = $out ? uc( $out ) : 'x' if vec( $self->{EIN}, $_, 1 ) ;
	       $out = '-' unless $out ;
	       $out ;
	    } (0..128)
	 ) ;
	 $map =~ s/((?:[a-zA-Z-]|\([^\)]*\)){12,}?)-*$/$1/ ;
	 _debug(
	    'selecting ', $map, ' with timeout=',
	    defined $timeout ? $timeout : 'forever'
	 ) ;
      }

      my $nfound = select(
         $self->{ROUT} = $self->{RIN},
	 $self->{WOUT} = $self->{WIN},
	 $self->{EOUT} = $self->{EIN},
	 $timeout 
      ) ;

      last if ! $nfound && $self->{non_blocking} ;

      croak "$! in select" if $nfound < 0 ;
      if ( $debug > 2 ) {
         my $map = join(
	    '',
	    map {
	       my $out ;
	       $out = 'r' if vec( $self->{ROUT}, $_, 1 ) ;
	       $out = $out ? 'b' : 'w' if vec( $self->{WOUT}, $_, 1 ) ;
	       $out = $out ? uc( $out ) : 'x' if vec( $self->{EOUT}, $_, 1 ) ;
	       $out = '-' unless $out ;
	       $out ;
	    } (0..128)
	 ) ;
	 $map =~ s/((?:[a-zA-Z-]|\([^\)]*\)){12,}?)-*$/$1/ ;
	 _debug "selected  ", $map ;
      }

      ## Need to copy since _clobber alters @{$self->{PIPES}}.
      ## TODO: Rethink _clobber().  Rething $file->{PAUSED}, too.
      my @pipes = @{$self->{PIPES}} ;
   FILE:
      for my $pipe ( @pipes ) {
         ## Pipes can be shared among kids.  If another kid closes the
	 ## pipe, then it's {FD} will be undef.
	 if ( $pipe->{TYPE} =~ /^>/
	    && defined $pipe->{FD}
	    && vec( $self->{ROUT}, $pipe->{FD}, 1 )
	 ) {
	    if ( $pipe->{IS_DEBUG} ) {
	       ## When receiving debug messages, use POSIX.  We don't want to 
	       ## have _read and _write log things for us.
	       my $in ;
	       my $c = POSIX::read( $pipe->{FD}, $in, 100000 ) ;
	       if( defined $c && $c > 0 ) {
		  POSIX::write( $debug_fd, $in, length $in ) ;
	       }
	       else {
	          $self->_clobber( $pipe ) ;
	       }

	       next FILE ;
	    }

	    _debug_fd( "filtering data from", $pipe ) if $debug > 2 ;
confess "fooy" unless isa( $pipe, "IPC::Run::IO" ) ;
	    $io_occurred = 1 if $pipe->_do_filters( $self ) ;

	    next FILE unless defined $pipe->{FD} ;
	 }

         ## Output pipes are not shared, AFAIK.  But I check for a defined {FD}
	 ## just in case.  Should probably just assert defined {FD}
	 if ( $pipe->{TYPE} =~ /^</
	    && defined $pipe->{FD}
	    && vec( $self->{WOUT}, $pipe->{FD}, 1 )
	 ) {
	    _debug_fd( "filtering data to", $pipe ) if $debug > 1 ;
	    $io_occurred = 1 if $pipe->_do_filters( $self ) ;

	    next FILE unless defined $pipe->{FD} ;
	 }

	 if ( defined $pipe->{FD} && vec( $self->{EOUT}, $pipe->{FD}, 1 ) ) {
	    ## BSD seems to sometimes raise the exceptional condition flag
	    ## when a pipe is closed before we read it's last data.  This
	    ## causes spurious warnings and generally renders the exception
	    ## mechanism mostly useless for our purposes.  The exception
	    ## flag semantics are too variable (they're device driver
	    ## specific) for me to easily map to any automatic action like
	    ## warning or croaking (try running v0.42 if you don't beleive me
	    ## :-).
#	    warn "Exception on descriptor $pipe->{FD}" ;
	 }
      }
   }

   return scalar( @{$self->{PIPES}} ) ;
}


sub _cleanup {
   my IPC::Run $self = shift ;
   my $num = 0 ;
   _debug "__cleaning up" ;

   for ( values %{$self->{PTYS}} ) {
      next unless ref $_ ;
      eval {
	 close $_->slave ;
      } ;
      carp $@ . " closing ptys" if $@ ;
      eval {
	 close $_ ;
      } ;
      carp $@ . " closing ptys" if $@ ;
   }
   
   ## _clobber modifies PIPES
   $self->_clobber( $self->{PIPES}->[0] ) while @{$self->{PIPES}} ;

   for my $kid ( @{$self->{KIDS}} ) {
      if ( ! length $kid->{PID} ) {
	 _debug 'never ran child ', $num++, ", can't reap" ;
	 for my $op ( @{$kid->{OPS}} ) {
	    _close( $op->{TFD} ) if defined $op->{TFD} ;
	 }
      }
      else {
	 _debug 'reaping child ', $num++, ' (pid ', $kid->{PID}, ')' ;
	 my $pid = waitpid $kid->{PID}, 0 ;
	 $kid->{RESULT} = $? ;
	 _debug 'reaped ', $pid, ', $?=', $kid->{RESULT} ;
      }

      if ( defined $kid->{DEBUG_FD} ) {
         @{$kid->{OPS}} = grep
	    ! defined $_->{KFD} || $_->{KFD} != $kid->{DEBUG_FD},
	    @{$kid->{OPS}} ;
	 $kid->{DEBUG_FD} = undef ;
      }

      for my $op ( @{$kid->{OPS}} ) {
	 @{$op->{FILTERS}} = grep {
	    my $filter = $_ ;
	    ! grep $filter == $_, @{$self->{TEMP_FILTERS}} ;
	 } @{$op->{FILTERS}} ;
      }

   }
   $self->{STATE} = _finished ;
   @{$self->{TEMP_FILTERS}} = () ;
}


=item pump

   pump $h ;
   $h->pump ;

Pump accepts a single parameter harness.  It blocks until it delivers some
input or recieves some output.  It returns TRUE if there
is still input or output to be done, FALSE otherwise.

pump() will automatically call start() if need be, so you may call harness()
then proceed to pump() if that helps you structure your application.

Calling pump() when there is no more i/o do be done causes a "process ended
prematurely" exception to be thrown.  This allows fairly simple scripting
of external applications without having to add lots of error handling code
at each step of the script:

   $h = harness \@smbclient, \$in_q, \$out_q, $err_q ;

   $in_q = "cd /foo\n" ;
   $h->pump until $out_q =~ /^smb.*> \Z/m ;
   die "error cding to /foo:\n$out_q" if $out_q =~ "ERR" ;
   $out_q = '' ;

   $in_q = "mget *\n" ;
   $h->pump until $out_q =~ /^smb.*> \Z/m ;
   die "error retrieving files:\n$out_q" if $out_q =~ "ERR" ;

   $h->finish ;

   warn $err_q if $err_q ;


=cut


sub pump {
   die "pump() takes only a a single harness as a parameter"
      unless @_ == 1 && isa( $_[0], __PACKAGE__ ) ;

   my IPC::Run $self = shift ;

   local $debug = $self->{debug} if defined $self->{debug} ;

   _debug "** pumping" ;

   my $r = eval {
      $self->start if $self->{STATE} < _started ;
      $self->{auto_close_ins} = 0 ;
      $self->{break_on_io} = 1 ;
      $self->_select_loop ;
   } ;
   if ( $@ ) {
      my $x = $@ ;
      _debug $x if $x ;
      eval { $self->_cleanup } ;
      warn $@ if $@ ;
      die $x ;
   }
   return $r ;
}


=item pump_nb

   pump_nb $h ;
   $h->pump_nb ;

"pump() non-blocking", pumps if anything's ready to be pumped, returns
immediately otherwise.  This is useful if you're doing some long-running
task in the foreground, but don't want to starve any child processes.

=cut

sub pump_nb {
   my IPC::Run $self = shift ;

   ## Remember to uncomment this if we add any debug()ing here
#   local $debug = $self->{debug} if defined $self->{debug} ;

   $self->{non_blocking} = 1 ;
   my $r = eval { $self->pump } ;
   $self->{non_blocking} = 0 ;
   die $@ if $@ ;
   return $r ;
}

=item pumpable

Returns TRUE if calling pump() won't throw an immediate "process ended
prematurely" exception.  Reflects the value returned from the last call
to pump().

=cut

sub pumpable {
   my IPC::Run $self = shift ;
   return scalar @{$self->{PIPES}} ;
}


=item finish

This must be called after the last start() or pump() call for a harness,
or your system will accumulate defunct processes and you may "leak"
file descriptors.

finish() returns TRUE if all children returned 0 (and were not signaled and
did not coredump, ie ! $?), and FALSE otherwise (this
is like run(), and the opposite of system()).

Once a harness has been finished, it may be run() or start()ed again,
including by pump()s auto-start.

=cut


sub finish {
   my IPC::Run $self = shift ;
   my $options = @_ && ref $_[-1] eq 'HASH' ? pop : {} ;

   local $debug = $self->{debug} if defined $self->{debug} ;

   _debug "** finishing" ;

   eval {
      $self->{non_blocking} = 0 ;
      $self->{auto_close_ins} = 1 ;
      $self->{break_on_io} = 0 ;
      # We don't alter $self->{clear_ins}, start() and run() control it.

      $self->_select_loop( $options ) if @{$self->{PIPES}} ;
   } ;
   my $x = $@ ;
   _debug $x if $x ;
   eval { $self->_cleanup } ;
   warn $@ if $@ ;
   die $x if $x ;

   return ! $self->full_result ;
}


=item result

   $h->result ;

Returns the first non-zero result code (ie $? >> 8).  See L</full_result> to 
get the $? value for a child process.

To get the result of a particular child, do:

   $h->result( 0 ) ;  # first child's $? >> 8
   $h->result( 1 ) ;  # second child

or

   ($h->results)[0]
   ($h->results)[1]

Returns undef if no child processes were spawned and no child number was
specified.  Throws an exception if an out-of-range child number is passed.

=cut

sub _assert_finished {
   my IPC::Run $self = $_[0] ;

   croak "Harness not run" unless $self->{STATE} >= _finished ;
   croak "Harness not finished running" unless $self->{STATE} == _finished ;
}


sub result {
   &_assert_finished ;
   my IPC::Run $self = shift ;
   
   if ( @_ ) {
      my ( $which ) = @_ ;
      croak(
         "Only ",
	 scalar( @{$self->{KIDS}} ),
         " child processes, no process $which"
      )
         unless $which >= 0 && $which <= $#{$self->{KIDS}} ;
      return $self->{KIDS}->[$which]->{RESULT} >> 8 ;
   }
   else {
      return undef unless @{$self->{KIDS}} ;
      for ( @{$self->{KIDS}} ) {
	 return $_->{RESULT} >> 8 if $_->{RESULT} >> 8 ;
      }
   }
}


=item results

Returns a list of child exit values.  See L</full_results> if you want to
know if a signal killed the child.

Throws an exception if the harness is not in a finished state.
 
=cut

sub results {
   &_assert_finished ;
   my IPC::Run $self = shift ;

   return map $_->{RESULT} >> 8, @{$self->{KIDS}} ;
}


=item full_result

   $h->full_result ;

Returns the first non-zero $?.  See L</result> to get the first $? >> 8 
value for a child process.

To get the result of a particular child, do:

   $h->full_result( 0 ) ;  # first child's $? >> 8
   $h->full_result( 1 ) ;  # second child

or

   ($h->full_results)[0]
   ($h->full_results)[1]

Returns undef if no child processes were spawned and no child number was
specified.  Throws an exception if an out-of-range child number is passed.

=cut

sub full_result {
   goto &result if @_ > 1 ;
   &_assert_finished ;

   my IPC::Run $self = shift ;

   return undef unless @{$self->{KIDS}} ;
   for ( @{$self->{KIDS}} ) {
      return $_->{RESULT} if $_->{RESULT} ;
   }
}


=item full_results

Returns a list of child exit values as returned by C<wait>.  See L</results>
if you don't care about coredumps or signals.

Throws an exception if the harness is not in a finished state.
 
=cut

sub full_results {
   &_assert_finished ;
   my IPC::Run $self = shift ;

   croak "Harness not run" unless $self->{STATE} >= _finished ;
   croak "Harness not finished running" unless $self->{STATE} == _finished ;

   return map $_->{RESULT}, @{$self->{KIDS}} ;
}


##
## Filter Scaffolding
##
use vars (
'$filter_op',        ## The op running a filter chain right now
'$filter_num'        ## Which filter is being run right now.
) ;

##
## A few filters and filter constructors
##

=back

=head1 FILTERS

These filters are used to modify input our output between a child
process and a scalar or subroutine endpoint.

=over

=item new_chunker

This breaks a stream of data in to chunks, based on an optional
scalar or regular expression parameter.  The default is the Perl
input record separator in $/, which is a newline be default.

   run( \@cmd,
      '>', new_chunker, \&lines_handler,
   ) ;

   run( \@cmd,
      '>', new_chunker( "\r\n" ), \&lines_handler,
   ) ;

Because this uses $/ by default, you should always pass in a parameter
if you are worried about other code (modules, etc) modifying $/.

If this filter is last in a filter chain that dumps in to a scalar,
the scalar must be set to '' before a new chunk will be written to it.

As an example of how a filter like this can be written, here's a
chunker that splits on newlines:

   sub line_splitter {
      my ( $in_ref, $out_ref ) = @_ ;

      return 0 if length $$out_ref ;

      return input_avail && do {
	 while (1) {
	    if ( $$in_ref =~ s/\A(.*?\n)// ) {
	       $$out_ref .= $1 ;
	       return 1 ;
	    }
            my $hmm = get_more_input ;
	    unless ( defined $hmm ) {
	       $$out_ref = $$in_ref ;
	       $$in_ref = '' ;
	       return length $$out_ref ? 1 : 0 ;
	    }
	    return 0 if $hmm eq 0 ;
	 }
      }
   } ;

=cut

sub new_chunker(;$) {
   my ( $re ) = @_ ;
   $re = $/ if _empty $re ;
   $re = quotemeta( $re ) unless ref $re eq 'Regexp' ;
   $re = qr/\A(.*?$re)/s ;

   return sub {
      my ( $in_ref, $out_ref ) = @_ ;

      return 0 if length $$out_ref ;

      return input_avail && do {
	 while (1) {
	    if ( $$in_ref =~ s/$re// ) {
	       $$out_ref .= $1 ;
	       return 1 ;
	    }
            my $hmm = get_more_input ;
	    unless ( defined $hmm ) {
	       $$out_ref = $$in_ref ;
	       $$in_ref = '' ;
	       return length $$out_ref ? 1 : 0 ;
	    }
	    return 0 if $hmm eq 0 ;
	 }
      }
   } ;
}


=item new_appender

This appends a fixed string to each chunk of data read from the source
scalar or sub.  This might be useful if you're writing commands to a
child process that always must end in a fixed string, like "\n":

   run( \@cmd,
      '<', new_appender( "\n" ), \&commands,
   ) ;

Here's a typical filter sub that might be created by new_appender():

   sub newline_appender {
      my ( $in_ref, $out_ref ) = @_ ;

      return input_avail && do {
	 $$out_ref = join( '', $$out_ref, $$in_ref, "\n" ) ;
	 $$in_ref = '' ;
	 1 ;
      }
   } ;

=cut

sub new_appender($) {
   my ( $suffix ) = @_ ;
   croak "\$suffix undefined" unless defined $suffix ;

   return sub {
      my ( $in_ref, $out_ref ) = @_ ;

      return input_avail && do {
	 $$out_ref = join( '', $$out_ref, $$in_ref, $suffix ) ;
	 $$in_ref = '' ;
	 1 ;
      }
   } ;
}


sub new_string_source {
   my $ref ;
   if ( @_ > 1 ) {
      $ref = [ @_ ],
   }
   else {
      $ref = shift ;
   }

   return ref $ref eq 'SCALAR'
      ? sub {
	 my ( $in_ref, $out_ref ) = @_ ;

	 return defined $$ref
	    ? do {
	       $$out_ref .= $$ref ;
	       my $r = length $$ref ? 1 : 0 ;
	       $$ref = undef ;
	       $r ;
	    }
	    : undef
      }
      : sub {
	 my ( $in_ref, $out_ref ) = @_ ;

	 return @$ref
	    ? do {
	       my $s = shift @$ref ;
	       $$out_ref .= $s ;
	       length $s ? 1 : 0 ;
	    }
	    : undef ;
      }
}


sub new_string_sink {
   my ( $string_ref ) = @_ ;

   return sub {
      my ( $in_ref, $out_ref ) = @_ ;

      return input_avail && do {
	 $$string_ref .= $$in_ref ;
	 $$in_ref = '' ;
	 1 ;
      }
   } ;
}


#=item timeout
#
#This function defines a time interval, starting from when start() is
#called, or when timeout() is called.  If all processes have not finished
#by the end of the timeout period, then a "process timed out" exception
#is thrown.
#
#The time interval may be passed in seconds, or as an end time in
#"HH:MM:SS" format (any non-digit other than '.' may be used as
#spacing and puctuation).  This is probably best shown by example:
#
#   $h->timeout( $val ) ;
#
#   $val                     Effect
#   ======================== =====================================
#   undef                    Timeout timer disabled
#   ''                       Almost immediate timeout
#   0                        Almost immediate timeout
#   0.000001                 timeout > 0.0000001 seconds
#   30                       timeout > 30 seconds
#   30.0000001               timeout > 30 seconds
#   10:30                    timeout > 10 minutes, 30 seconds
#
#Timeouts are currently evaluated with a 1 second resolution, though
#this may change in the future.  This means that setting
#timeout($h,1) will cause a pokey child to be aborted sometime after
#one second has elapsed and typically before two seconds have elapsed.
#
#This sub does not check whether or not the timeout has expired already.
#
#Returns the number of seconds set as the timeout (this does not change
#as time passes, unless you call timeout( val ) again).
#
#The timeout does not include the time needed to fork() or spawn()
#the child processes, though some setup time for the child processes can
#included.  It also does not include the length of time it takes for
#the children to exit after they've closed all their pipes to the
#parent process.
#
#=cut
#
#sub timeout {
#   my IPC::Run $self = shift ;
#
#   if ( @_ ) {
#      ( $self->{TIMEOUT} ) = @_ ;
#      $self->{TIMEOUT_END} = undef ;
#      if ( defined $self->{TIMEOUT} ) {
#	 if ( $self->{TIMEOUT} =~ /[^\d.]/ ) {
#	    my @f = split( /[^\d\.]+/i, $self->{TIMEOUT} ) ;
#	    unshift @f, 0 while @f < 3 ;
#	    $self->{TIMEOUT} = (($f[0]*60)+$f[1])*60+$f[2] ;
#	 }
#	 elsif ( $self->{TIMEOUT} =~ /^(\d*)(?:\.(\d*))/ ) {
#	    $self->{TIMEOUT} = $1 + 1 ;
#	 }
#	 $self->_calc_timeout_end if $self->{STATE} >= _started ;
#      }
#   }
#   return $self->{TIMEOUT} ;
#}
#
#
#sub _calc_timeout_end {
#   my IPC::Run $self = shift ;
#
#   $self->{TIMEOUT_END} = defined $self->{TIMEOUT} 
#      ? time + $self->{TIMEOUT}
#      : undef ;
#
#   ## We add a second because we might be at the very end of the current
#   ## second, and we want to guarantee that we don't have a timeout even
#   ## one second less then the timeout period.
#   ++$self->{TIMEOUT_END} if $self->{TIMEOUT} ;
#}
#
=item io

Takes a filename or filehandle, a redirection operator, optional filters,
and a source or destination (depends on the redirection operator).  Returns
an IPC::Run::IO object suitable for harness()ing (including via start()
or run()).

This is shorthand for 


   require IPC::Run::IO ;

      ... IPC::Run::IO->new(...) ...

=cut

sub io {
   require IPC::Run::IO ;
   IPC::Run::IO->new( @_ ) ;
}

=item timer

   $h = start( \@cmd, \$in, \$out, $t = timer( 5 ) ) ;

   pump $h until $out =~ /expected stuff/ || $t->is_expired ;

Instantiates a non-fatal timer.  pump() returns once each time a timer
expires.  Has no direct effect on run(), but you can pass a subroutine
to fire when the timer expires. 

See L</timeout> for building timers that throw exceptions on
expiration.

See L<IPC::Run::Timer/timer> for details.

=cut

# Doing the prototype suppresses 'only used once' on older perls.
sub timer ;
*timer = \&IPC::Run::Timer::timer ;


=item timeout

   $h = start( \@cmd, \$in, \$out, $t = timeout( 5 ) ) ;

   pump $h until $out =~ /expected stuff/ ;

Instantiates a timer that throws an exception when it expires.
If you don't provide an exception, a default exception that matches
/^IPC::Run: .*timed out/ is thrown by default.  You can pass in your own
exception scalar or reference:

   $h = start(
      \@cmd, \$in, \$out,
      $t = timeout( 5, exception => 'slowpoke' ),
   ) ;

or set the name used in debugging message and in the default exception
string:

   $h = start(
      \@cmd, \$in, \$out,
      timeout( 50, name => 'process timer' ),
      $stall_timer = timeout( 5, name => 'stall timer' ),
   ) ;

   pump $h until $out =~ /started/ ;

   $in = 'command 1' ;
   $stall_timer->start ;
   pump $h until $out =~ /command 1 finished/ ;

   $in = 'command 2' ;
   $stall_timer->start ;
   pump $h until $out =~ /command 2 finished/ ;

   $in = 'very slow command 3' ;
   $stall_timer->start( 10 ) ;
   pump $h until $out =~ /command 3 finished/ ;

   $stall_timer->start( 5 ) ;
   $in = 'command 4' ;
   pump $h until $out =~ /command 4 finished/ ;

   $stall_timer->reset; # Prevent restarting or expirng
   finish $h ;

See L</timer> for building non-fatal timers.

See L<IPC::Run::Timer/timer> for details.

=cut

# Doing the prototype suppresses 'only used once' on older perls.
sub timeout ;
*timeout = \&IPC::Run::Timer::timeout ;


=back

=head1 FILTER IMPLEMENTATION FUNCTIONS

These functions are for use from within filters.

=over

=item input_avail

Returns TRUE if input is available.  If none is available, then 
&get_more_input is called and it's result returned.

This is usually used in preference to &get_more_input so that the
calling filter removes all data from the $in_ref before more data
gets read in to $in_ref.

C<get_more_input> is usually used as part of a return expression:

   return input_avail && do {
      ## process the input just gotten
      1 ;
   } ;

This technique allows get_more_input to return the undef or 0 that a
filter normally returns when there's no input to process.  If a filter
stores intermediate values, however, it will need to react to an
undef:

   my $got = input_avail ;
   if ( ! defined $got ) {
      ## No more input ever, flush internal buffers to $out_ref
   }
   return $got unless $got ;
   ## Got some input, move as much as need be
   return 1 if $added_to_out_ref ;

=cut

sub input_avail() {
   confess "Undefined FBUF ref for $filter_num+1"
      unless defined $filter_op->{FBUFS}->[$filter_num+1] ;
   length ${$filter_op->{FBUFS}->[$filter_num+1]} || get_more_input ;
}


=item get_more_input

This is used to fetch more input in to the input variable.  It returns
undef if there will never be any more input, 0 if there is none now,
but there might be in the future, and TRUE if more input was gotten.

C<get_more_input> is usually used as part of a return expression,
see L</input_avail> for more information.

=cut

##
## Filter implementation interface
##
sub get_more_input() {
   ++$filter_num ;
   my $r = eval {
      confess "get_more_input() called and no more filters in chain"
         unless defined $filter_op->{FILTERS}->[$filter_num] ;
      $filter_op->{FILTERS}->[$filter_num]->(
         $filter_op->{FBUFS}->[$filter_num+1],
         $filter_op->{FBUFS}->[$filter_num],
      ) ; # if defined ${$filter_op->{FBUFS}->[$filter_num+1]} ;
   } ;
   --$filter_num ;
   die $@ if $@ ;
   return $r ;
}

=item filter_tests

   my @tests = filter_tests( "foo", "in", "out", \&filter ) ;
   $_->() for ( @tests ) ;

This creates a list of test subs that can be used to test most filters
for basic functionality.  The first parameter is the name of the
filter to be tested, the second is sample input, the third is the
test(s) to apply to the output(s), and the rest of the parameters are
the filters to be linked and tested.

If the filter chain is to be fed multiple inputs in sequence, the second
parameter should be a reference to an array of thos inputs:

   my @tests = filter_tests( "foo", [qw(1 2 3)], "123", \&filter ) ;

If the filter chain should produce a sequence of outputs, then the
thrid parameter should be a reference to an array of those outputs:

   my @tests = filter_tests(
      "foo",
      "1\n\2\n",
      [ qr/^1$/, qr/^2$/ ],
      new_chunker
   ) ;

See t/run.t and t/filter.t for an example of this in practice.

=cut

##
## Filter testing routines
##
sub filter_tests($;@) {
   my ( $name, $in, $exp, @filters ) = @_ ;

   my @in  = ref $in  eq 'ARRAY' ? @$in  : ( $in  ) ;
   my @exp = ref $exp eq 'ARRAY' ? @$exp : ( $exp ) ;

   require Test ;
   *ok = \&Test::ok ;

   my IPC::Run::IO $op ;
   my $output ;
   my @input ;
   my $in_count = 0 ;

   my @out ;

   my $h = harness() ;

   return (
      sub {
	 $op = IPC::Run::IO->_new_internal( '<', 0, 0, 0,
	       new_string_sink( \$output ),
	       @filters,
	       new_string_source( \@input ),
	 ) ;
	 $op->_init_filters ;
	 @input = () ;
	 $output = '' ;
	 ok(
	    ! defined $op->_do_filters( $h ),
	    1,
	    "$name didn't pass undef (EOF) through"
	 ) ;
      },

      ## See if correctly does nothing on 0, (please try again)
      sub {
         $op->_init_filters ;
	 $output = '' ;
	 @input = ( '' ) ;
	 ok(
	    $op->_do_filters( $h ),
	    0,
	    "$name didn't return 0 (please try again) when given a 0"
	 ) ;
      },

      sub {
	 @input = ( '' ) ;
	 ok(
	    $op->_do_filters( $h ),
	    0,
	    "$name didn't return 0 (please try again) when given a second 0"
	 ) ;
      },

      sub {
	 for (1..100) {
	    last unless defined $op->_do_filters( $h ) ;
	 }
	 ok(
	    ! defined $op->_do_filters( $h ),
	    1,
	    "$name didn't return undef (EOF) after two 0s and an undef"
	 ) ;
      },

      ## See if it can take @in and make @out
      sub {
         $op->_init_filters ;
	 $output = '' ;
	 @input = @in ;
	 while ( defined $op->_do_filters( $h ) && @input ) {
	    if ( length $output ) {
	       push @out, $output ;
	       $output = '' ;
	    }
	 }
	 if ( length $output ) {
	    push @out, $output ;
	    $output = '' ;
	 }
	 ok(
	    scalar @input,
	    0,
	    "$name didn't consume it's input"
	 ) ;
      },

      sub {
	 for (1..100) {
	    last unless defined $op->_do_filters( $h ) ;
	    if ( length $output ) {
	       push @out, $output ;
	       $output = '' ;
	    }
	 }
	 ok(
	    ! defined $op->_do_filters( $h ),
	    1,
	    "$name didn't return undef (EOF), tried  100 times"
	 ) ;
      },

      sub {
	 ok(
	    join( ', ', map "'$_'", @out ),
	    join( ', ', map "'$_'", @exp ),
	    $name
	 )
      },

   ) ;
}


=back

=head1 TODO

These will be addressed as needed and as time allows.

Stall timeout.

Expose a list of child process objects.  When I do this,
each child process is likely to be blessed into IPC::Run::Proc.

$kid->abort(), $kid->kill(), $kid->signal( $num_or_name ).

Write tests for /(full_)?results?/ subs.

Currently, pump() and run() only work on systems where select() works on the
filehandles returned by pipe().  This does *not* include Win32.  I'd
like to rectify that, suggestions and patches welcome.

Likewise start() only fully works on fork()/exec() machines (well, just
fork() if you only ever pass perl subs as subprocesses).  There's
some scaffolding for calling Open3::spawn_with_handles(), but that's
not that useful with limited select().

Support for C<\@sub_cmd> as an argument to a command which
gets replaced with /dev/fd or the name of a temporary file containing foo's
output.  This is like <(sub_cmd ...) found in bash and csh (IIRC).

Allow multiple harnesses to be combined as independant sets of processes
in to one 'meta-harness'.

Allow a harness to be passed in place of an \@cmd.

Ability to add external file descriptors w/ filter chains and endpoints.

Ability to add timeouts and timing generators (i.e. repeating timeouts).

High resolution timeouts.

=head1 LIMITATIONS

No support for ';', '&&', '||', '{ ... }', etc: use perl's, since run()
returns TRUE when the command exits with a 0 result code.

Does not provide shell-like string interpolation.

No support for C<cd>, C<setenv>, or C<export>: do these in an init() sub

   run(
      \cmd,
         ...
	 init => sub {
	    chdir $dir or die $! ;
	    $ENV{FOO}='BAR'
	 }
   ) ;

Timeout calculation does not allow absolute times, or specification of
days, months, etc.

=head1 INSPIRATION

Well, select() and waitpid() badly needed wrapping, and open3() isn't
open-minded enough for me.

API inspired by a message Russ Allbery sent to perl5-porters, which
included:

   I've thought for some time that it would be
   nice to have a module that could handle full Bourne shell pipe syntax
   internally, with fork and exec, without ever invoking a shell.  Something
   that you could give things like:

   pipeopen (PIPE, [ qw/cat file/ ], '|', [ 'analyze', @args ], '>&3');

Message ylln51p2b6.fsf@windlord.stanford.edu, on 2000/02/04.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>, with numerous suggestions by p5p.

=cut

1 ;
