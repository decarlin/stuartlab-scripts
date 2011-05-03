#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## make_network_corr.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

use strict;
use warnings;

my $templates_dir = &getMapDir('templates');

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',              0,     1]
                 ,[    '-p', 'scalar', 'Network/Corr',     1]
                 ,[    '-m', 'scalar', "$templates_dir/Make/network_corr.mak",     1]
                 ,[  '-run', 'scalar',              0,     1]
                 ,[    '-r', 'scalar',              0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $path     = $args{'-p'};
my $makefile = $args{'-m'};
my $run      = $args{'-run'} + $args{'-r'};
my @dirs     = @{$args{'--extra'}};

if(scalar(@dirs) == 0)
{
   @dirs = ('.');
}

my @dirs_with_data;

foreach my $dir (@dirs)
{
   if(-f "$dir/data.tab")
   {
      $verbose and
         print STDERR "Directory '$dir' is OK, it has a data.tab.\n";

      push(@dirs_with_data, $dir);
   }
   else
   {
      $verbose and
         print STDERR "WARNING: Skipping directory '$dir' since no data.tab exists in it.\n";
   }
}

foreach my $dir (@dirs_with_data)
{
   &setupMake("$dir/$path", $makefile);
}

if($run)
{
   foreach my $dir (@dirs_with_data)
   {
      &runMake("$dir/$path");
   }
}
else
{
   $verbose and
      print STDERR "The directories are now set.\n"
                 , "To compute correlations, go into each and\n"
                 , "run make.  Alternatively, run this script\n"
                 , "again with the -run option.\n"
                 ;
}

sub setupMake
{
   my ($path, $makefile) = @_;

   if(-d $path)
   {
      $verbose and print STDERR "Excellent, the directory '$path' already exists.\n";
   }
   else
   {
      $verbose and print STDERR "Creating directory '$path'.";
      system("mkdir -p $path");
      $verbose and print STDERR "  Done.\n";
   }

   if((-l "$path/Makefile") or (-f "$path/Makefile"))
   {
      $verbose and print STDERR "Good, the $path/Makefile already exists.\n";
   }
   else
   {
      $verbose and print STDERR "Linking $path/Makefile to $makefile.";
      system("cd $path; ln -s $makefile Makefile");
      $verbose and print STDERR "  Done.\n";
   }
}

sub runMake
{
   my ($path) = @_;
   $verbose and print STDERR "Calling make to compute correlations.\n";
   system("cd $path; make");
}

exit(0);

__DATA__
syntax: make_network_corr.pl [OPTIONS] [DIR1 DIR2 ...]

Should be run from a data set underneath:

Data/Expression/ORGANISM/X

where ORGANISM is the MAP handle of an organism and
X is the dataset for which a correlation network is
to be computed.

If a set of directories are given DIRi's the script computes
a network in each directory that has a data.tab file.

OPTIONS are:

-p PATH: Specify the path where the network correlations should
         be stored.  The default is Network/Corr.

-m MAKEFILE: Specify the make to link this makefile to.  The
             default is $MAPDIR/Templates/Make/network_corr.mak.

-run: Call make to actually compute the correlations.  By default
      the script.

