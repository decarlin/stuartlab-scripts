#!/usr/bin/perl

##############################################################################
##############################################################################
##
## download_smd_pub_meta.pl
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
                , ['--file', 'scalar',   undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $smd_url   = $args{'-u'};
my $dir       = $args{'-d'};
my @extra     = @{$args{'--extra'}};
my $pub_id    = $extra[0];

defined($pub_id) or die("Please supply a publication ID.");

my $pub_url      = "$smd_url/$pub_id";

my $pub_meta_url = "$pub_url/publication_$pub_id.meta";

my $pub_meta     = &download($pub_meta_url, $dir);

$verbose and print STDERR "Downloaded and saved file '$dir/$pub_meta'.\n";

exit(0);

__DATA__
syntax: download_smd_pub_meta.pl [OPTIONS] PUBID

Downloads the publication meta file from SMD.

OPTIONS are:

-q: Quiet mode (default is verbose)

-u URL: Set the URL base for where SMD publications can be found.

-d DIR: Specify where downloaded data file(s) are saved (default is Remote/).

