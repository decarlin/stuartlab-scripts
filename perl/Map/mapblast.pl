#!/usr/bin/perl

##############################################################################
##############################################################################
##
## mapblast.pl
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
require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libblast.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',          0,     1]
                , [    '-c', 'scalar',          4, undef]
                , [    '-n', 'scalar',          1, undef]
                , [    '-p', 'scalar',      undef, undef]
                , [    '-t', 'scalar',          0,     1]
                , [    '-e', 'scalar',     10**-5, undef]
                , [  '-dna', 'scalar',      undef,     1]
                , [  '-pro', 'scalar',      undef,     1]
                , [ '-ddna', 'scalar',      undef,     1]
                , [ '-dpro', 'scalar',      undef,     1]
                , [ '-qdna', 'scalar',      undef,     1]
                , [ '-qpro', 'scalar',      undef,     1]
                , [  '-exe', 'scalar', 'blastall', undef]
                , ['--file',   'list',      ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $cpus      = $args{'-c'};
my $n         = $args{'-n'};
my $program   = $args{'-p'};
my $translate = $args{'-t'};
my $eval_cut  = $args{'-e'};
my $dna_both  = $args{'-dna'};
my $pro_both  = $args{'-pro'};
my $ddna      = $args{'-ddna'};
my $dpro      = $args{'-dpro'};
my $qdna      = $args{'-qdna'};
my $qpro      = $args{'-qpro'};
my $exe       = $args{'-exe'};
my @files     = @{$args{'--file'}};
my @extra     = @{$args{'--extra'}};

scalar(@files) >= 1 or die("No query file supplied");

my $query_file = shift @files;

my $used_tmp = 0;

if($query_file eq '-')
{
   my $tmp = time . '.' . int(rand(100000)) . '.tmp';
   open(TMP, ">$tmp") or die("Could not open temporary file '$tmp'");
   while(<STDIN>)
   {
      print TMP $_;
   }
   close(TMP);

   $query_file = $tmp;

   $used_tmp = 1;
}

$qpro    = (defined($dna_both) or defined($qdna)) ? 0 :
              (defined($pro_both) or defined($qpro)) ? 1 : undef;
$dpro    = (defined($dna_both) or defined($ddna)) ? 0 :
              (defined($pro_both) or defined($dpro)) ? 1 : undef;
$program = defined($program) ? $program : &getBlastProgram($query_file, $qpro, $dpro);
$dpro    = (($program eq 'blastp') or ($program eq 'blastx')) ? 1 : 0;

my $database = undef;
if(scalar(@extra) > 0)
{
   my $arg = shift(@extra);
   my $org = &getMapOrganismName($arg);
   if($org =~ /\S/)
   {
      $database = &getMapBlastDb($org, $dpro);
   }
   else
   {
      $database = $arg;
   }
}
else
{
   $database = &getMapBlastDb('human', $dpro);
}

my $command = $exe
              . " -p $program"
              . " -i $query_file"
              . " -d $database"
              . " -m 8"
              . " -a $cpus"
              . " " . join(" ", @extra);
              ;

$verbose and print STDERR "Executing '$command'.\n";

open(BLAST, "$command |") or die("Could not execute command '$command'");

my @hits;
my $prev_query = undef;
my $num_queries = 0;
while(<BLAST>)
{
   $num_queries++;

   chomp;

   my ($query,
       $hit,
       $perc,
       $len,
       $qframe,
       $hframe,
       $qbeg,
       $qend,
       $hbeg,
       $hend,
       $eval,
       $bits);

   my $idk;

   if($program eq 'blastn')
   {
      ($query,
       $hit,
       $perc,
       $len,
       $qframe,
       $hframe,
       $qbeg,
       $qend,
       $hbeg,
       $hend,
       $eval,
       $bits) = split("\t");
   }
   elsif($program eq 'blastx')
   {
      ($query,
       $hit,
       $perc,
       $len,
       $idk,
       $qframe,
       $qbeg,
       $qend,
       $hbeg,
       $hend,
       $eval,
       $bits) = split("\t");
   }

   else
   {
      ($query,
       $hit,
       $perc,
       $len,
       $qbeg,
       $qend,
       $hbeg,
       $hend,
       $eval,
       $bits) = split("\t");
   }

   if(scalar(@hits) > 0 and defined($prev_query) and ($query ne $prev_query))
   {
      my $besthit = &getLongestBlastHit(\@hits);

      print STDERR $num_queries . ". " . $prev_query, "\t", join("\t", @{$besthit}), "\n";

      print STDOUT $prev_query, "\t", join("\t", @{$besthit}), "\n";

      @hits = ();
   }

   elsif(defined($prev_query) and ($query ne $prev_query))
   {
      $verbose and print STDERR "$num_queries. No significant BLAST hits found for query '$prev_query'\n";
   }

   if($eval <= $eval_cut)
   {
      push(@hits, [$hit, $qbeg, $qend, $perc]);
   }
   else
   {
      # $verbose and print STDERR "'$query' E-value '$eval' too big (> $eval_cut).\n";
   }

   $prev_query = $query;
}
close(BLAST);

if(scalar(@hits) > 0)
{
   my $besthit = &getLongestBlastHit(\@hits);

   print STDERR $num_queries . ". " . $prev_query, "\t", join("\t", @{$besthit}), "\n";

   print STDOUT $prev_query, "\t", join("\t", @{$besthit}), "\n";
}
elsif(defined($prev_query))
{
   $verbose and print STDERR "No significant BLAST hits found for the last query '$prev_query'\n";
}

if($used_tmp)
{
   system("rm -f $query_file");
}

exit(0);


__DATA__
syntax: mapblast.pl [OPTIONS] QUERY [DATABASE | ORGANISM]

Wrapper around the blastall program.

Performs a BLAST search for every sequence in the file QUERY
against the protein database specified by either a database file prefix (using
the DATABASE argument) or an organism.

QUERY    - Set of FASTA formatted sequences used as the query.

DATABASE - The database to search against.  If not supplied then the script figures
           it out based on the query sequence.

ORGANISM - The organism to blast the query against.

If no DATABASE or ORGANISM is supplied the blast assumes human.

OPTIONS are:

-q: Quiet mode (default is verbose)

-c CPUS: Use CPUS number of processors (default is 4).

-n NUM: Keep the top NUM hits for each query (default is 1).

-t: Translate.  Only applies to cases where the query and the database are both
    nucleotides (this runs tblastx instead of blastn).

-e EVAL: Set the E-value cutoff to EVAL (default is 1e-10).  Only hits equal to or
         below this cutoff are considered.

-dna: The query and database are DNA sequences.

-pro: The query and database are protein sequences.

-ddna: The database only is a set of DNA sequences.

-dpro: The database has protein sequences.

-qdna: The query set has DNA sequences.

-qpro: The query has protein sequences.

-exe EXE: Change the BLAST executable to EXE (defaut is blastall).

-p PROGRAM: Force the BLAST program to be PROGRAM (default is undefined and the
            correct program is determined based on the query and database types.
            e.g. for a DNA query and a protein database blastx would be used).

