#!/usr/bin/perl

package librandom;

# Alex Williams
# 2007
#
# This file should have random-number-generating things in it

# to include this file, in your own file you should say:
#    use lib "$ENV{MYPERLDIR}/lib";
#    use librandom;
# at the top of your file
#
# You can then call: librandom::random_exponential()
# in the body of your program
# Or, if you want, you can import these functions into the local
# namespace so that you don't have to say "librandom::" each time.

use strict;
use warnings;

use Exporter;
@Exporter::ISA = qw(Exporter);
@Exporter::EXPORT_OK = qw(&random_exponential  &random_gaussian);

# Note: (;$) means that the argument is OPTIONAL
sub random_exponential(;$) { # exponential rand (like "rexp" in R) (takes lambda as an argument)
    # I think this is right, and I plotted it out in R with the histogram, but no guarantees!
    my ($lambda) = @_;
    if (!defined($lambda)) { $lambda = 1; } # <-- default value
    # http://en.wikipedia.org/wiki/Exponential_distribution#Generating_exponential_variates
    # Note that "log" in perl is ln (the natural logarithm)
    my $uniformRand = rand(1);
    return (-log($uniformRand) / $lambda);

}

sub random_gaussian(;$$) { # By default, generates a (mean = 0, stdev = 1) number
    # Function adapted from the O'Reilly Perl Cookbook: http://www.unix.org.ua/orelly/perl/cookbook/ch02_11.htm
    # "The gaussian_rand function implements the polar Box Muller method for turning two
    # independent uniformly distributed random numbers between 0 and 1 (such as rand returns)
    # into two numbers with a mean of 0 and a standard deviation of 1 (i.e., a Gaussian distribution)"
    # "To generate numbers with a different mean and standard deviation, multiply the output of gaussian_rand by the new standard deviation, and then add the new mean"
    my ($mean, $sd) = @_;

    if (!defined($mean)) { $mean = 0; }
    if (!defined($sd))   { $sd   = 1; }

    my ($u1, $u2);  # uniformly distributed random numbers
    my $w;          # variance, then a weight
    my ($g1, $g2);  # gaussian-distributed numbers
    do {
	$u1 = (2*rand()) - 1;
	$u2 = (2*rand()) - 1;
	$w = ($u1*$u1) + ($u2*$u2);
    } while ($w >= 1);
    $w = sqrt( (-2*log($w))  / $w );
    $g2 = $u1 * $w;
    $g1 = $u2 * $w;
    
    my $scaled1 = ($g1*$sd) + $mean;
    my $scaled2 = ($g2*$sd) + $mean;
    
    return wantarray ? ($scaled1, $scaled2) : $scaled1;    # return both if wanted, else just one
}




1; # <-- this is important! keep it at the end of the file!
