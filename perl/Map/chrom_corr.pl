#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-z', 'scalar',     0,     1]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-s', 'scalar',     0,     1]
                , [    '-h', 'scalar',     1, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose         = not($args{'-q'});
my $K               = $args{'-k'};
my $use_zscores     = $args{'-z'};
my $delim           = $args{'-d'};
my $headers         = $args{'-h'};
my $sorted          = $args{'-s'};
my @files           = @{$args{'--file'}};
my @extra           = @{$args{'--extra'}};

$K = defined($K) ? $K : (scalar(@extra) > 0 ? $extra[0] : 1);

my $line;
my %expression;


if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

scalar(@files) == 2 or die("Please supply an EXPRESSION and a POSITIONS file");

$K >= 1 or die("The value of K must be greater or equal to 1");

# Print a header out.
print STDOUT "Gene\tChromosome\tStart";
for(my $i = -$K; $i <= $K; $i++)
{
   if($i != 0)
   {
      print STDOUT "\t$i";
   }
}
print STDOUT "\n";

open(XPR, $files[0])
        or die "The gene expression file '$files[0]' does not exist. \n";

$verbose and print STDERR "Reading in expression data.\n";
my $passify = 1000;
my $iter    = 0;
while (<XPR>)
{
   my @line = split("\t");
   chomp($line[$#line]);
   my $gene = shift @line;

   my $len = scalar(@line);
   for(my $i = 0; $i < $len; $i++)
   {
      if(not($line[$i] =~ /\d/))
      {
         $line[$i] = undef;
      }
   }

   $expression{$gene} = \@line;

   $iter++;
   if($verbose and $iter % $passify == 0)
   {
      print STDERR "$iter expression vectors read.\n";
   }
}
close(XPR);
$verbose and print STDERR "Done reading in expression data.\n";

##################

open(POS, $files[1])
        or die "The genome positions file '$files[1]' does not exist.";

$verbose and print STDERR "Reading in position data.\n";
my @positions;
$iter = 0;
while (<POS>)
{
   chomp;
   my @list = split("\t");
   push(@positions, \@list);

   $iter++;
   if($verbose and $iter % $passify == 0)
   {
      print STDERR "$iter positions read.\n";
   }
}
close(POS);
$verbose and print STDERR "Done reading in position data.\n";

##################

# exit(0);

##################

my $results = &computeGeneCorrelations(\%expression, \@positions, $K, $sorted, $use_zscores, \*STDOUT);

# Exit successfully.
exit(0);

###############################################################################
#
# \@results computeGeneCorrelations(\%expression, \@positions, $K-value,
#                                   $int is_sorted=0, $int use_zscores=0,
#                                   \*FILE file=undef)
#
###############################################################################

sub computeGeneCorrelations
{
   my ($expression, $positions, $K, $is_sorted, $use_zscores, $file) = @_;
   $K           = defined($K) ? $K : 1;
   $is_sorted   = defined($is_sorted) ? $is_sorted : 0;
   $use_zscores = defined($use_zscores) ? $use_zscores : 0;

   my @results;

   my %expression = %{$expression};
   my @positions  = @{$positions};

   my $N = scalar(@positions);

   # Sort by chromosome and then by start position.
   my @sorted;
   if(not($is_sorted))
   {
      @sorted = sort { $$a[1] <=> $$b[1] || $$a[2] <=> $$b[2] } @positions;
   }


   my $list_1;
   my $gene_1;
   my $chrom_1;
   my $start_1;
   # my $end_1;
   # my $operon_1;
   # my $paralog_1;
   my $expr_1;

   my $list_2;
   my $gene_2;
   my $chrom_2;
   my $start_2;
   # my $end_2;
   # my $operon_2;
   # my $paralog_2;
   my $expr_2;

   my $correlation;
   my $dimensions;
   my $result;

   my $passify = 100;
   my $iter    = 0;
   my $total   = ($N - 1) * $K * 2;

   for(my $i = 0; $i < $N - 1 ; $i++)
   {
      $list_1    = $is_sorted ? $positions[$i] : $sorted[$i];
      $gene_1    = $$list_1[0];
      $chrom_1   = $$list_1[1];
      $start_1   = $$list_1[2];
      # $end_1     = defined($$list_1[3]) ? $$list_1[3] : undef;
      # $operon_1  = defined($$list_1[4]) ? $$list_1[4] : undef;
      # $paralog_1 = defined($$list_1[5]) ? $$list_1[5] : undef;
      $expr_1    = exists($expression{$gene_1}) ? $expression{$gene_1} : undef;
      $result    = $gene_1 . "\t" . $chrom_1 . "\t" . $start_1;

      # exists($expression{$gene_1}) or print STDERR "No expression for '$gene_1'\n";

      # for(my $j = 0; $j < $K and $N > $i+$j+1; $j++)
      # for(my $j = $i + 1; $j <= $i + $K; $j++)
      for(my $k = -$K; $k <= $K; $k++)
      {
         my $j = $i + $k;

         if($j != $i and $j >= 0 and $j < $N)
         {
            $list_2  = $is_sorted ? $positions[$j] : $sorted[$j];
            $gene_2  = $$list_2[0];
            $chrom_2 = $$list_2[1];
            $start_2 = $$list_2[2];
            if($chrom_1 eq $chrom_2 and defined($expr_1) and exists($expression{$gene_2}))
            {
               $expr_2       = $expression{$gene_2};
               ($correlation, $dimensions) = &computeCorrelation($expr_1, $expr_2);
               if($use_zscores)
               {
                  $correlation = &Pearson2FisherZscore($correlation, $dimensions);
               }
               $result      .= defined($correlation) ? "\t" . sprintf("%5.3f", $correlation) : "\t";
            }
            else
            {
               $result .= "\t";
            }

            $iter++;

            if($verbose and $iter % $passify == 0)
            {
               my $perc_done = int($iter / $total * 100.0);
               my $type      = $use_zscores ? 'Fisher Z-scores' : 'Pearson correlations';
               print STDERR "$iter $type computed ($perc_done% done).\n";
            }
         }
         elsif($j != $i)
         {
            $result .= "\t";
         }

      }

      push(@results, $result);

      if(defined($file))
      {
         print $file $result, "\n";
      }
   }
   return \@results;
}



###############################################################################
#
# ($double, $int) computeCorrelation(\@expression_1, \@expression_2)
#
###############################################################################

sub computeCorrelation
{
   my ($x,$y) = @_;

   if(not(defined($x)) or not(defined($y)))
      { return undef; }

   my $correlation = 0.0;

   my ($N, $Sxy, $Sx, $Sy, $Sx_2, $Sy_2)   = &sigma($x, $y);

   my $numerator =   $N*$Sxy - $Sx*$Sy ;
   my $denom_1   =   $N*$Sx_2 - ($Sx)**2;
   my $denom_2   =   $N*$Sy_2 - ($Sy)**2;

   if ( $N == 0 )
      { $correlation = undef; }

   elsif ( $denom_1 <= 0 )
      { $correlation = undef; }

   elsif ( $denom_2 <= 0 )
      { $correlation = undef; }

   else
      { $correlation = $numerator/sqrt($denom_1*$denom_2); }

   return ($correlation, $N);
}



###############################################################################
#
# sigma(\@x, \@y)
# return ($N, $Sxy, $Sx, $Sy, $Sx_2, $Sy_2)
#
###############################################################################

sub sigma
{
   my ($x, $y) = @_;
   my @x = @{$x};
   my @y = @{$y};
   my $len = scalar(@x);
   my ($N, $Sxy, $Sx, $Sy, $Sx_2, $Sy_2) = (0,0,0,0,0,0);

   for (my $i = 0; $i < $len; $i++)
   {
      if(defined($x[$i]) and defined($y[$i]))
      {
         $N    += 1;
         $Sx   += $x[$i];
         $Sy   += $y[$i];
         $Sx_2 += ($x[$i])**2;
         $Sy_2 += ($y[$i])**2;
         $Sxy  += ($x[$i] * $y[$i]);
      }
   }
   return ($N, $Sxy, $Sx, $Sy, $Sx_2, $Sy_2);
}



__DATA__
syntax: chrom_correlation.pl [OPTIONS] EXPRESSION POSITIONS K

This script computes the correlations between gene neighbors.  It takes two
files as input:

EXPRESSION -- a tab-delimited file containing the expression profiles of
              the genes.

POSITIONS  -- a tab-delimited file containing the genome position
              information of the genes.

K          -- a number.

OPTIONS are:

-z: Print Fisher Z-scores instead of pearson correlations.

-s: The positions are already sorted, so don't re-sort (default sorts by chromosome
    and then by start position).



