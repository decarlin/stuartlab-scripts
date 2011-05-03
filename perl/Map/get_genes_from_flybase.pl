#!/usr/bin/perl

use strict;

my $info_type = 'flybase_id';
my $fin = \*STDIN;
my $get_genes       = 0;
my $get_genbank     = 0;
my $get_proteins     = 0;
my $get_aliases     = 0;
while(@ARGV)
{
  my $arg = shift;

  if($arg eq '--help')
  {
    print STDERR <DATA>;
    exit(0);
  }

  elsif($arg eq '-genes')
  {
    $get_genes = 1;
  }

  elsif($arg eq '-proteins')
  {
    $get_proteins = 1;
  }

  elsif($arg eq '-alias')
  {
    $get_aliases = 1;
  }

  elsif($arg eq '-genbank')
  {
    $get_genbank = 1;
  }

  elsif($arg eq '-all')
  {
    $get_genbank = 1;
    $get_proteins = 1;
    $get_aliases = 1;
  }

  elsif(-f $arg)
  {
    open($fin,$arg) or die("Could not open '$arg' for reading.");
  }
  
  else
  {
    die("Bad argument '$arg' given.");
  }
}

my $flybase_id = '';
my $computed_gene;
my @computed_transcripts;
my @transcripts;
my @aliases;
my @genbank_accessions;
while(<$fin>)
{
  if(/\S/)
  {
    if(/^\s*#/)
    {
      if(length($flybase_id)>0)
      {
	if(length($computed_gene)>0)
	{
	  print $flybase_id, "\t", $computed_gene, "\n";
	}

	foreach my $computed_transcript (@computed_transcripts)
	{
	  print $flybase_id, "\t", $computed_transcript, "\n";
	}

	foreach my $alias (@aliases)
	{
	  print $flybase_id, "\t", $alias, "\n";
	}

	foreach my $genbank_accession (@genbank_accessions)
	{
	  print $flybase_id, "\t", $genbank_accession, "\n";
	}

        $flybase_id = '';
        $computed_gene = '';
        @computed_transcripts = ();
        @aliases = ();
        @genbank_accessions = ();
      }
    }

    elsif(/^\s*\*z\s+(\S+)/)
    {
      $flybase_id = $1;
    }

    elsif($get_genes and /^\s*\*i\s+[Cc][Gg](\d+)/)
    {
      $computed_gene = 'CG' . $1;
    }

    # Computed transcripts
    elsif($get_proteins and /^\s*\*J/ and /pp-[Cc][Tt](\d+)/)
    {
      my $computed_transcript = 'CT' . $1;
      push(@computed_transcripts,$computed_transcript);
    }

    # Computed aliases
    elsif($get_aliases and /^\s*\*i\s+(.+)$/)
    {
      my $alias = $1;
      $alias =~ s/\s+$//;
      push(@aliases,$alias);
    }

    # Genbank accessions
    elsif($get_genbank and /^\s*\*g\s+(.+)$/)
    {
      my $acc = $1;
      my @accs = split(';',$acc);
      foreach $acc (@accs)
      {
        # Only put accessions that don't have database qualifiers on them.  For example
        # entries from the Berkeley Drosophila Genome Project all have entries like
        # BDGP:DS08613 or dbSTS entries look like dbSTS:1234.
        if(not($acc =~ /:/))
        {
	  $acc =~ s/\s//g;
          push(@genbank_accessions,$acc);
        }
      }
    }
  }
}

exit(0);

__DATA__
syntax: get_genes_from_flybase.pl [OPTIONS] < FILE

Reads in a Flybase-formatted report and extract information about the genes.  It outputs:

FLYBASE_ID <tab> COMPUTED_GENE

OPTIONS are:

-genes: Output the computed genes

-proteins: Extract computed transcripts (those that start with
           CT).  This will output a column with the transcripts.

-alias: Print out anything that looks like an alias (*i lines in FlyBase)

-genbank: Output genbank accessions as well.  The output will be:

    FLYBASE_ID <tab> ACCESSION

    This will also print blanks for COMPUTED_GENE if an accession exists while a CG entry does
    not.

-all: Print out computed genes, transcripts, genbank accessions, and aliases.
-
