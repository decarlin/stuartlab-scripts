#!/usr/bin/perl

use strict;

my $blastdb_dir = '/firepower/sc1/bio_data/blast/db';
my $protein_dir = '/firepower/sc1/bio_data/blast/test';
my $blastout_dir = '/firepower/sc1/bio_data/blast/test/out';
# my ($blastdb_dir,$protein_dir,$blastout_dir) = @ARGV;

my $verbose=1;

if(not(-d $protein_dir))
{
  die("Protein directory '$protein_dir' does not exist.");
}

if(not(opendir(DIR,$protein_dir)))
{
  die("Could not open protein directory '$protein_dir'.");
}

if(not(-d $blastdb_dir))
{
  die("Blast database directory '$blastdb_dir' does not exist.\n");
}

if(not(-d $blastout_dir))
{
  die("Blast output directory '$blastout_dir' does not exist.\n");
}

my @files = readdir(DIR);
closedir(DIR);

my @genomes;
foreach my $file (@files)
{
  if($file =~ /^(\S+)\.faa$/)
  {
    push(@genomes,$1);
  }
}

for(my $i=0; $i<=$#genomes; $i++)
{
  my $genome_db = $genomes[$i];
  for(my $j=0; $j<=$#genomes; $j++)
  {
    my $query_genome = $genomes[$j];
    my $outdir = $blastout_dir . '/' . 
                            $query_genome . '_' . $genome_db;
    if(not(-d $outdir))
    {
      mkdir($outdir) or die("Could not create output directory '$outdir'\n");
      not($verbose) or print STDERR "Created output directory '$outdir'\n";
    }
    my $db = $blastdb_dir . '/' . $genome_db . '.faa';
    my $query = $protein_dir . '/' . $query_genome . '.faa';

    not(-f $query) and die("The query file '$query' does not exist.");

    not($verbose) or 
      print STDERR "Blasting $query_genome (query) against $genome_db (database)\n";
    my $blast_command = "blast_all.pl $outdir $db $query";
    # not($verbose) or 
    #   print STDERR "Executing '$blast_command'\n";
    `$blast_command`;
  }
}


