#!/usr/bin/perl

##############################################################################
##############################################################################
##
## chrom2xy.pl
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
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-k', 'scalar',     1, undef]
                , [    '-c', 'scalar',     2, undef]
                , [    '-b', 'scalar',     3, undef]
                , [    '-p', 'scalar', undef, undef]
                , [   '-px', 'scalar',     0, undef]
                , [   '-py', 'scalar',     0, undef]
                , [    '-s', 'scalar', undef, undef]
                , [   '-sx', 'scalar',     1, undef]
                , [   '-sy', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my $key_col   = $args{'-k'} - 1;
my $chr_col   = $args{'-c'} - 1;
my $beg_col   = $args{'-b'} - 1;
my $pad       = $args{'-p'};
my $pad_x     = $args{'-px'};
my $pad_y     = $args{'-py'};
my $scale     = $args{'-s'};
my $scale_x   = $args{'-sx'};
my $scale_y   = $args{'-sy'};
my $file      = $args{'--file'};

$pad_x   = defined($pad)   ? $pad   : $pad_x;
$pad_y   = defined($pad)   ? $pad   : $pad_y;
$scale_x = defined($scale) ? $scale : $scale_x;
$scale_y = defined($scale) ? $scale : $scale_y;

$verbose and print STDERR "Reading in positions.\n";
my $filep     = &openFile($file);
my $line_no   = 0;
my $max_beg = undef;
my %positions;
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      my @x = split($delim, $_);
      chomp($x[$#x]);
      my ($gene, $chrom, $beg) = ($x[$key_col], $x[$chr_col], $x[$beg_col]);

      if($gene =~ /\S/ and not($chrom =~ /\D/) and not($beg =~ /\D/))
      {
         push(@{$positions{$chrom}}, [$gene, $beg]);
         if(not(defined($max_beg)) or $beg > $max_beg)
         {
            $max_beg = $beg;
         }
      }
   }
}
close($filep);

my $num_chroms = scalar(keys(%positions));

$verbose and print STDERR "Done reading, $num_chroms chromosomes read (maximum beg position = $max_beg).\n";

print STDOUT "Gene\tX\tY\n";
foreach my $chrom (sort {$a <=> $b;} keys(%positions))
{
   my $chrom_positions = $positions{$chrom};

   my $y = $pad_y + ($scale_y - 2 * $pad_y) * (($chrom - 1) / ($num_chroms - 1));

   foreach my $position (@{$chrom_positions})
   {
      my ($gene, $beg) = @{$position};

      my $x = $pad_x + ($scale_x - 2 * $pad_x) * ($beg / $max_beg);

      print STDOUT $gene, "\t", $x, "\t", $y, "\n";

      # print $gene, "\t", $chrom, "\t", $beg, "\n";
   }
}

exit(0);


__DATA__
syntax: chrom2xy.pl [OPTIONS] FILE

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-k COL: Set the gene key column to COL (default is 1).

-c COL: Set the chromosome column to COL (default is 2).

-b COL: Set the beg position column to COL (default is 3).

-p PADDING: Set the padding to PADDING (default is 0).

-px PADDING: Set the padding to PADDING for the x-dimension (default is 0).

-py PADDING: Set the padding to PADDING for the y-dimension (default is 0).

-s  SCALE: set the scale for both x- and y-dimensions to SCALE (default is 1).

-sx SCALE: Scale just the x-dimension by a constant factor SCALE (default is 1).

-sy SCALE: Scale just the y-dimension by a constant factor SCALE (default is 1).


