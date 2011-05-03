#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cels2tab.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-c', 'scalar',   0.5, undef]
                , [    '-f', 'scalar', undef, undef]
                , [    '-s', 'scalar',    '', undef]
                , [    '-p', 'scalar',    '', undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $coefvar_cutoff = $args{'-c'};
my $file_list      = $args{'-f'};
my $suffix         = $args{'-s'};
my $prefix         = $args{'-p'};
my @files          = @{$args{'--file'}};
my @names          = ();

if(defined($file_list) and open(LIST, $file_list))
{
   print STDERR "Reading list of files from '$file_list'.\n";
   while(<LIST>)
   {
      chomp;
      my ($file, $name) = split("\t");
      push(@files, $file);
      push(@names, $name);
   }
   close(LIST);
   print STDERR "Done reading the list of files.\n";
}

for(my $i = 0; $i < scalar(@files); $i++)
{
   if(not(defined($names[$i])))
   {
      $names[$i] = $files[$i];
   }
}

my %spots;
my @matrix;
my @xys;
my $r = -1;
my @header = ('Spot');
for(my $i = 0; $i < scalar(@files); $i++)
{
   my $file = $prefix . $files[$i] . $suffix;

   if(open(FILE, $file))
   {
      push(@header, $names[$i]);

      my $saw_header = 0;

      my $done = 0;

      print STDERR "Reading data from file '$file'.\n";

      my $total_spots = 0;

      my $good_spots = 0;

      while(not($done))
      {
	 my $line = <FILE>;

         if($line =~ /^CellHeader=X/)
	 {
	    $saw_header = 1;
	 }
	 elsif($saw_header and $line =~ /^\s*$/)
	 {
	    $done = 1;
	 }
	 elsif($saw_header)
	 {
	    chomp($line);

	    $line =~ s/[ ]+//g;

	    my ($x,$y,$mu,$stdev,$pixels) = split("\t", $line);

	    my $spot = "$x,$y";

	    if(not(exists($spots{$spot})))
	    {
	       $r++;

	       $spots{$spot} = $r;

	       push(@xys, $spot);
	    }

	    my $row = $spots{$spot};

	    # If the coefficient of variation is too high, 
	    # then mark the data as missing.  If it's bigger
	    # than half of the mean, let's toss it.

	    my $coefvar = $stdev / $mu;

	    my $mu_print = '';

	    if($coefvar < $coefvar_cutoff)
	    {
	       $good_spots++;

	       $mu_print = "$mu";
	    }

	    push(@{$matrix[$row]}, $mu_print);

	    $total_spots++;
	 }
      }
      print STDERR "Done.  $good_spots out of $total_spots good spots found.\n";

      close(FILE);
   }
   else
   {
      print STDERR "Could not open file '$file', skipping.";
   }
}

print STDERR "Printing out the data matrix.\n";

print join("\t", @header), "\n";

my $passify = 1000;

my $num_rows = scalar(@matrix);

for(my $i = 0; $i < $num_rows; $i++)
{
   my $xy = $xys[$i];

   my $tuple = $matrix[$i];

   print STDOUT $xy, "\t", join("\t", @{$tuple}), "\n";

   if($verbose and (($i+1) % $passify == 0))
   {
      my $perc_done = int(($i + 1) / $num_rows * 100.0);

      print STDERR "$perc_done% done.\n";
   }
}

exit(0);


__DATA__
syntax: cels2tab.pl [OPTIONS] FILE1 [FILE2 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-c CUTOFF: Set the cutoff for the coefficient of variation.
           Any spot with a variation greater than CUTOFF will
	   be set to missing (default is 0.5).

-f FILELIST: Contains a list of file names as the first column.
             The script will then read the data from the files
	     specified in this file.  The header used can come
	     from an optional second column otherwise the filename
	     itself is used as the header for the column.

-p PREFIX: Add a prefix to the file names listed (default is blank)
           For example you can specify a directory like -p '../'.

-s SUFFIX: Add a suffix to the file names listed (default is blank)

