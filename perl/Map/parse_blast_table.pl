#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";
require "$ENV{MYPERLDIR}/lib/libblast.pl";

my $delim = "\t";

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my $blast_table_in = \*STDIN;
my $query_organism = '';
my $db_organism = '';
my $query_fasta = '';
my $db_fasta = '';
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-query')
  {
    $query_organism = shift @ARGV;
  }
  elsif($arg eq '-db')
  {
    $db_organism = shift @ARGV;
  }
  elsif((-f $arg) and length($query_fasta)==0)
  {
    $query_fasta = $arg;
  }
  elsif((-f $arg) and length($db_fasta)==0)
  {
    $db_fasta = $arg;
  }
  elsif(-f $arg)
  {
    open($blast_table_in,$arg) or die("Could not open BLAST table '$arg'.");
  }
  elsif(length($query_organism)==0)
  {
    $query_organism = $arg;
  }
  elsif(length($db_organism)==0)
  {
    $db_organism = $arg;
  }
  else
  {
    die("Bad argument '$arg' supplied.");
  }
}

length($query_fasta)>0 or die("Please supply a query FASTA file.");
length($db_fasta)>0 or die("Please supply a database FASTA file.");

if(length($query_organism)==0)
{
  $query_organism = &getMapOrganismFromPath($query_fasta);
}

if(length($db_organism)==0)
{
  $db_organism = &getMapOrganismFromPath($db_fasta);
}

my %query_errors;
my %database_errors;
my $opened_errors = 0;

# Get the lengths of all the query sequences
open(QUERY,"fasta2stab.pl < $query_fasta |") or 
  die("Could not open query FASTA file '$query_fasta'.");
my %query_lengths;
while(<QUERY>)
{
  if(/\S/)
  {
    chomp;
    my ($id,$seq) = split("\t");
    $query_lengths{$id} = length($seq);
  }
}
close(QUERY);

# Get the lengths of all the database sequences
my %db_lengths;
open(DB,"fasta2stab.pl < $db_fasta |") or 
  die("Could not open database FASTA file '$db_fasta'.");
while(<DB>)
{
  if(/\S/)
  {
    chomp;
    my ($id,$seq) = split("\t");
    $db_lengths{$id} = length($seq);
  }
}
close(DB);

my $query_col     = &getBlastTableColumn('query_id') - 1;
my $qbeg_col      = &getBlastTableColumn('query_beg') - 1;
my $qend_col      = &getBlastTableColumn('query_end') - 1;
my $hit_col       = &getBlastTableColumn('hit_id') - 1;
my $hbeg_col      = &getBlastTableColumn('hit_beg') - 1;
my $hend_col      = &getBlastTableColumn('hit_end') - 1;
my $identity_col  = &getBlastTableColumn('identity') - 1;
my $evalue_col    = &getBlastTableColumn('evalue') - 1;
my $bit_score_col = &getBlastTableColumn('bit_score') - 1;
my %best_evalue;
my %reports;
while(<$blast_table_in>)
{
  if(/\S/)
  {
    chomp;
    my @tuple = split("\t");
    my ($query,$qbeg,$qend,$hit,$hbeg,$hend,$identity,$evalue,$bit_score) =
       ($tuple[$query_col], $tuple[$qbeg_col], $tuple[$qend_col],
        $tuple[$hit_col], $tuple[$hbeg_col], $tuple[$hend_col],
        $tuple[$identity_col], $tuple[$evalue_col], $tuple[$bit_score_col]);
    
    # How long the match is along the query and hit:
    my $q_match = $qend - $qbeg + 1;
    my $h_match = $qend - $qbeg + 1;

    # The percentage of positions covered by the match:
    my $q_len  = $query_lengths{$query};
    my $h_len  = $db_lengths{$hit};

    my $q_perc = 0;
    if(defined($q_len) and $q_len>0)
    {
      $q_perc = int($q_match / $q_len * 10000.0)/100;
    }
    elsif(not(exists($query_errors{$query})))
    {
      if(not($opened_errors))
      {
        open(ERRORS, ">>errors.log") or die("Could not open error file 'errors.log'");
	$opened_errors = 1;
      }
      print ERRORS "query '$query', length = $q_len\n";
    }
    my $h_perc = 0;
    if(defined($h_len) and $h_len>0)
    {
      $h_perc = int($h_match / $h_len * 10000.0)/100;
    }
    elsif(not(exists($database_errors{$hit})))
    {
      if(not($opened_errors))
      {
        open(ERRORS, ">>errors.log") or die("Could not open error file 'errors.log'");
	$opened_errors = 1;
      }
      print ERRORS "database hit '$hit', length = $h_len\n";
    }

    my $store_report = 0;
    if(not(exists($best_evalue{$query,$hit})))
    {
      $best_evalue{$query,$hit} = $evalue;
      $store_report = 1;
    }
    else
    {
      my $best = $best_evalue{$query,$hit};
      if($best > $evalue)
      {
	$best_evalue{$query,$hit} = $evalue;
        $store_report = 1;
      }
    }

    if($store_report)
    {
      $reports{$query . $delim . $hit} =
            $query_organism . $delim .
            $db_organism . $delim .
            $query . $delim .
            $hit . $delim .
	    $q_len . $delim .
	    $h_len . $delim .
	    $q_perc . $delim .
	    $h_perc . $delim .
	    $identity . $delim .
	    $evalue;
    }
  }
}
close($blast_table_in);

if($opened_errors)
{
  close(ERRORS);
}

foreach my $query_hit (keys(%reports))
{
  my $report = $reports{$query_hit};
  print $report, "\n";
}

exit(0);

__DATA__
syntax: parse_blast_table.pl [OPTIONS] QUERY_FASTA DB_FASTA < BLAST_TABLE

Prints out a MAP BLAST summary table from a BLAST result table.

QUERY_FASTA: FASTA file containing the protein sequences used for the BLAST.

DB_FASTA: FASTA file containing the protein sequences used for the BLAST.  Note this
                is *not* the BLAST formatted database but the sequences used to construct it.

BLAST_TABLE: The result of calling blastall with the -m 8 option (tabular output).

OPTIONS are:

-query ORGANISM: specify the query organism to be ORGANISM.  If not supplied, the script
                 attempts to determine this from the MAP path of the QUERY_FASTA file.

-db ORGANISM: set the database organism to ORGANISM.  If not supplied, the script attempts
              to determine this from the MAP path of the DB_FASTA file.


