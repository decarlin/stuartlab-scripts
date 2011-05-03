#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    fasta_file - sequences in fasta format used as input
#    gene_list - the genes from the fasta file that we want to select
#    gene_file - the sql file that will be generated for loading the genes 
#    sequence_file - the sql file that will be generated for loading the sequences
#    binding_file - the sql file that will be generated for loading the bindings 
#    lmer - the size of the lmer that will be used
#    start_promoter_position - we copy start_promoter_position .. end_promoter_position from the promoter
#    end_promoter_position - we copy start_promoter_position .. end_promoter_position from the promoter
# output:
#    sets the three sql files that can then be loaded into mysql
#-----------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
  chop;
  
  ($id, $value) = split(/=/, $_, 2);
  
  $settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
$fasta_file = $settings{"fasta_file"};
open(FASTA_FILE, "<$fasta_file");

$gene_list = $settings{"gene_list"};
open(GENE_LIST, "<$gene_list");

$gene_file = $settings{"gene_file"};
open(GENES, ">$gene_file");

$sequence_file = $settings{"sequence_file"};
open(SEQUENCES, ">$sequence_file");

$binding_file = $settings{"binding_file"};
open(BINDINGS, ">$binding_file");

$lmer = $settings{"lmer"};
$start_promoter_position = $settings{"start_promoter_position"};
$end_promoter_position = $settings{"end_promoter_position"};

$gene_id = 0;
while(<GENE_LIST>)
{
  chop;
  /([^\s]*).*/;

  $genes{$1} = "1";
  $gene_name_to_gene_id{$1} = $gene_id;
  $gene_id++;
}

$sequence_id = 0;
$binding_id = 0;
$total_promoter_length = 0;
while(<FASTA_FILE>)
{
  chop;

  if (/>([^\s\t]*).*/)
  {
	if ($genes{$1} eq "1")
	{
	  $genes_found_in_fasta{$1} = "1";
	  $base_binding_id = $sequence_id - $total_promoter_length;
	  for ($i = 0; $i < $total_promoter_length - $lmer + 1; $i++)
	  {
		print BINDINGS $binding_id . "\t" . $gene_id . "\t";
		for ($j = 0; $j < $lmer; $j++)
		{
		  print BINDINGS ($base_binding_id + $i + $j) . "\t";
		}
		print BINDINGS "\n";
		$binding_id++;
	  }

	  $total_promoter_length = 0;
	  $total_offset = 0;

	  $gene_id = $gene_name_to_gene_id{$1};
	  $current_gene = $1;

	  print GENES $gene_id . "\t" . $1 . "\t\n";
	}
	else 
	{
	  $current_gene = "dummy";
	}
  }
  else
  {
	if ($genes{$current_gene} eq "1")
	{
	  $gene_id = $gene_name_to_gene_id{$current_gene};
	  $found = 1;
	  $offset = 0;
	  while ($found == 1)
	  {
		$s = substr($_,$offset,1);
		if (!$s)
		{
		  #print "end at $offset\n";
		  $found = 0;
		}
		else
		{
		  $total_offset++;
		  if ($total_offset >= $start_promoter_position && $total_offset <= $end_promoter_position)
		  {
			print SEQUENCES $sequence_id . "\t" . $gene_id . "\t" . $s . "\t\n";
			$sequence_id++;
			$total_promoter_length++;
		  }
		}
		$offset++;
	  }
	}
  }
 
  #if ($gene_id == 4) { exit; }
}

$base_binding_id = $sequence_id - $total_promoter_length;
for ($i = 0; $i < $total_promoter_length - $lmer + 1; $i++)
{
  print BINDINGS $binding_id . "\t" . $gene_id . "\t";
  for ($j = 0; $j < $lmer; $j++)
  {
	print BINDINGS ($base_binding_id + $i + $j) . "\t";
  }
  print BINDINGS "\n";
  $binding_id++;
}

$first = 1;
foreach $gene (keys(%gene_name_to_gene_id))
{
  if ($genes_found_in_fasta{$gene} ne "1")
  {
	if ($first == 1)
	{
	  print "I did not find the following genes in the fasta file\n";
	  $first = 0;
	}
	print $gene . "\n";
  }
}
