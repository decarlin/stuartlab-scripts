#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## correct_multi_pvals.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
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
                , [    '-h', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-n', 'scalar', undef, undef]
                , [    '-a', 'scalar',  0.05, undef]
                , [    '-s', 'scalar',     0,     1]
                , [    '-l', 'scalar', undef, undef]
                , [   '-nl', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = &interpMetaChars($args{'-d'});
my $headers = int($args{'-h'});
my $n       = $args{'-n'};
my $alpha   = $args{'-a'};
my $sorted  = $args{'-s'};
my $logged  = $args{'-l'};
my $nlogged = $args{'-nl'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my $filep = &openFile($file);
my @pvals;
my $index = 0;
my $already_printed = 0;
my %index2result;
my $line = 0;
while(<$filep>) {
   $line++;
   if($line > $headers) {
      my @x = split($delim, $_);
      chomp($x[$#x]);
      my $pval  = $x[$col];
      if(&isEmpty($pval)) {
         $pval = 1;
      }
      elsif(defined($nlogged)) {
         $pval = $nlogged ** -$pval;
      }
      elsif(defined($logged)) {
         $pval = $logged ** $pval;
      }
      push(@pvals, [$index,$pval]);

      if($sorted and defined($n)) {
         if(&isEmpty($pval)) {
            print STDOUT "$pval\tNaN\tNaN\n";
         }
         else {
            my ($crit,$sig) = &getBHResult($pval, $index+1, $alpha, $n);
            $crit = &maybeLogThis($crit, $logged, $nlogged);
            print STDOUT "$pval\t$crit\t$sig\n";
         }
      }
      else {
         $index2result{$index} = [$pval,undef,undef];
      }
      $index++;
   }
}
close($filep);

if(defined($n) and $sorted) {
   $already_printed = 1;
}

my $m = scalar(@pvals);
if(not(defined($n))) {
   $n = $m;
}

if(not($sorted)) {
   @pvals = sort {$$a[1]<=>$$b[1];} @pvals;
}

if(not($already_printed)) {
   for(my $i = 0; $i < $m; $i++) {
      my ($index,$pval) = @{$pvals[$i]};
      if(not(&isEmpty($pval))) {
         my ($crit,$sig) = &getBHResult($pval, $i+1, $alpha, $n);
         my ($o, $c, $s) = @{$index2result{$index}};
         $index2result{$index} = [$o,$crit,$sig];
      }
   }
   for(my $i = 0; $i < $m; $i++) {
      my ($pval, $crit, $sig) = @{$index2result{$i}};
      if(&isEmpty($pval)) {
         print STDOUT "$pval\tNaN\tNaN\n";
      }
      else {
         $crit = &maybeLogThis($crit, $logged, $nlogged);
         print STDOUT "$pval\t$crit\t$sig\n";
      }
   }
}

exit(0);

sub maybeLogThis {
   my ($val, $log_base, $neg_log_base) = @_;
   if(defined($log_base)) {
      $val = log($val) / log($log_base);
   }
   elsif(defined($neg_log_base)) {
      $val = -log($val) / log($neg_log_base);
   }
   return $val;
}

sub getBHResult {
   my ($p, $k, $a, $num) = @_;
   # Compute the B-H critical value.
   my $critical = $k * $a / 2.0 / $num;
   my $signif = $p < $critical ? '1' : '0';
   return ($critical,$signif);
}

__DATA__
syntax: correct_multi_pvals.pl [OPTIONS]

Given a column of p-values, reports which p-values are significant. The program corrects
for multiple testing. By default, it uses the Benjamini-Hochberg approach such that the
ith smallest p-value must be less than i*alpha / 2 / n where alpha is the significance
level and n is the number of tests.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the column to read p-values from to COL (default is 1, the first column).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-n N: Set the number of tests to N. The default is the number of p-values in the file.

-a ALPHA: Set the significance level to ALPHA (default is 0.05).

-s: Indicate that the p-values are already sorted from smallest to largest. By default,
    the script will sort. This can save time if a large file needs to be processed.

-l BASE: Specify that the p-values have already been log-transformed to base BASE. E.g.
         -l 2 indicates that the column should be interpreted as log_2(p).

-nl BASE: Specify that the p-values input have been negative log-transformed to base BASE. E.g.
          -nl 2 indicates that the column should be interpreted as -log_2(p).


