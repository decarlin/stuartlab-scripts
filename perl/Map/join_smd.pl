#!/usr/bin/perl

##############################################################################
##############################################################################
##
## join_smd.pl
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
## Written: 9/22/03
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libsmd.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',                0,     1]
                , [    '-g', 'scalar',           'NAME', undef]
                , [    '-d', 'scalar', 'LOG_RAT2N_MEAN', undef]

              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $gene_field = $args{'-g'};
my $data_field = $args{'-d'};
my @extra      = @{$args{'--extra'}};

((scalar(@extra) == 1) and (-d $extra[0]))
   or die("Please supply a directory");

my $dir = $extra[0];

my @files = &getAllFilesRecursively(1, $dir);

print STDERR "Found:\n", join("\n", @files);

my @tmps;

foreach my $file (@files)
{
   if($file =~ /\.xls$/)
   {
      my ($expt_id, $expt_name) = &getSmdExptInfoFromXls($file);

      my $expt = "$expt_id;$expt_name";

      my $tmp = $expt_id . '.tmp';

      my $cmd = "strings $file "
                . "| grep -v '^!' "
                . "| projection.pl -f '^$gene_field\$' -f $data_field "
                . "| body.pl 2 -1 "
                . "| uniq.pl -a 2,ave "
                . "| cap.pl ORF,'$expt' "
                . "> $tmp;"
                ;

      $verbose and print STDERR "Executing `$cmd`\n";

      `$cmd`;

      push(@tmps, $tmp);
   }
}

if(scalar(@tmps) > 0)
{
   my $cmd = "head -n 1 $tmps[0] > 1.tmp; "
             . "body.pl 2 -1 " . join(" ", @tmps)
             . " | cut -f 1"
             . " | sort -u"
             . " >> 1.tmp"
             ;

   $verbose and print STDERR "Executing `$cmd`\n";

   `$cmd`;

   my $result = '1.tmp';

   for(my $i = 0; $i < scalar(@tmps); $i++)
   {
      my $cmd = "join.pl -o NaN 1.tmp $tmps[$i] > 2.tmp;"
                . " mv 2.tmp 1.tmp; "
                . " rm -f $tmps[$i]; "
                ;

      $verbose and print STDERR "Executing `$cmd`\n";

      `$cmd`;
   }

   system("cat 1.tmp");

   system("rm -f 1.tmp");
}

exit(0);

__DATA__
syntax: join_smd.pl [OPTIONS] DIR

OPTIONS are:

-q: Quiet mode (default is verbose)

-g GENE_FIELD: The field in the SMD file containing the gene names (default is NAME).

-d DATA_FIELD: The field that has the expression data (default is LOG_RAT2N_MEAN).


