#!/usr/bin/perl

##############################################################################
##############################################################################
##
## download_smd_pub_data.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',       0,     1]
                , [    '-u', 'scalar', 'ftp://genome-ftp.stanford.edu/pub/smd/publications', undef]
                , [    '-d', 'scalar','Remote', undef]
                , [    '-j', 'scalar',       0,     1]
                , [    '-r', 'scalar',       0,     1]
                , ['--file', 'scalar',   undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $smd_url   = $args{'-u'};
my $dir       = $args{'-d'};
my $join      = $args{'-j'};
my $remove    = $args{'-r'};
my $pub_meta  = $args{'--file'};

(-f $pub_meta) or die("Please supply an SMD publication meta file");

my $pub_id    = &getPubId($pub_meta);

my $pub_url      = "$smd_url/$pub_id";

my $pub_meta_url = "$pub_url/publication_$pub_id.meta";

my @expt_sets = @{&getExptSets($pub_meta)};

scalar(@expt_sets) > 0 or die("No experiment sets found for '$pub_meta'");

foreach my $expt_set (@expt_sets)
{
   my $expt_tgz   = "exptsetno_$expt_set.tar.gz";

   my $expt_url   = "$pub_url/$expt_set/$expt_tgz";

   # my $downloaded = &download($expt_url, $dir);
   my $downloaded = '';

   my $pwd = `pwd`; chomp($pwd);

   my $cmd = "cd $dir;"
             . " zcat ../$downloaded"
             . " | tar -xvf -;"
             . " cd $pwd;"
             . " rm -f $downloaded;"
             ;

   $verbose and print STDERR "Executing '$cmd'\n";

   # `$cmd`;

    &download("$pub_url/$expt_set", $dir, 'xls');
}

if($join)
{
   my $cmd = "join_smd.pl .;";

   $verbose and print STDERR "Executing '$cmd'\n";

   system("$cmd");
}

if($remove)
{
   system("rm -rf $dir/*");
}

exit(0);

sub getPubId
{
   my ($pub_meta) = @_;

   my $pub_id = undef;

   if($pub_meta =~ /publication_(\d+)/)
   {
      $pub_id = $1;
   }

   return $pub_id;
}

sub getExptSets
{
   my ($meta_file) = @_;

   my $meta_filep = &openFile($meta_file);

   my @list;

   while(my $line = <$meta_filep>)
   {

      if($line =~ /!ExptSetNo\s*=\s*(\d+)/)
      {
         push(@list, $1);
      }
   }

   close($meta_filep);

   return \@list;
}

__DATA__
syntax: download_smd_pub_data.pl [OPTIONS] PUBMETA

Downloads the necessary files from the Stanford Microarray Database
described in the publication meta file PUBMETA.

OPTIONS are:

-q: Quiet mode (default is verbose)

-u URL: Set the URL base for where SMD publications can be found.

-d DIR: Specify where downloaded data file(s) are saved (default is Remote/).

-j: Join the resulting files (default does not glue all together).

-r: Remove the directory created after extracting the SMD tar file (only useful
    if also using the -j option).



