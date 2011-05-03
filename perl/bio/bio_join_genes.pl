#! /usr/bin/perl

#--------------------------------------------------------------------------------------------------------------------------------------------------
# input:
#    BJG_join_top_expressions - the actual expression file
#    BJG_num_headings - the number of column headers that the expression file has BEFORE the actual data columns
#    BJG_gene_name_location_within_heading - position of gene_name
#    BJG_number_from_top - take only the first number_from_top genes from the gene_list file 
#    BJG_num_header_rows - the number of rows before the first line containing a gene information
#    BJG_join_genes_list - the list of genes to extract from the expression file or "ALL" for no selection
#    BJG_join_experiments_list - the list of experiments to extract from the expression file or "ALL" for no selection
#    BJG_join_format - if it's sql then we create two sql file tables, it it's pcluster then we create a file in pcluster format
#    BJG_missing_value_fill - put this string instead of missing values
#    BJG_out_expressions - the output expressions file
#    BJG_out_genes - the output genes file
#    BJG_out_experiments - the output experiments file
#
#    BJG_num_experiment_groups - (works only with format of sql) the number of experiment groups that will be placed together (e.g. for time series)
#    BJG_experiment_group_i - (works only with format of sql) a list of the experiment names, separated by semicolons (e.g. nitrogen 1;nitrogen 2)
# output:
#
#--------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_dsc.pl";

my %settings = load_settings($ARGV[0]);

my $expressions = $settings{"BJG_join_top_expressions"};
my $num_headings = $settings{"BJG_num_headings"};
my $gene_name_location_within_heading = $settings{"BJG_gene_name_location_within_heading"};
my $number_from_top = $settings{"BJG_number_from_top"};
my $num_header_rows = $settings{"BJG_num_header_rows"};
my $join_genes_list = $settings{"BJG_join_genes_list"};
my $join_experiments_list = $settings{"BJG_join_experiments_list"};
my $join_format = $settings{"BJG_join_format"};
my $missing_value_fill = $settings{"BJG_missing_value_fill"};
my $out_expressions = $settings{"BJG_out_expressions"};
my $out_genes = $settings{"BJG_out_genes"};
my $out_experiments = $settings{"BJG_out_experiments"};
my $num_experiment_groups = $settings{"BJG_num_experiment_groups"};
my @num_experiments_in_group_i;
my $num_experiments;

open(OUT_EXPRESSIONS, ">$out_expressions") or die "could not open $out_expressions";
if ($join_format eq "sql")
{
  open(OUT_GENES, ">$out_genes") or die "could not open $out_genes";
  open(OUT_EXPERIMENTS, ">$out_experiments") or die "could not open $out_experiments";
}

my %gene_ids;
my %genes;

my %experiment_ids;
my %experiments;
my %experiment_columns;

my $num_missing_values = 0;

#---------------------------------------------------------------------------
# load the experiment groups
#---------------------------------------------------------------------------
sub load_experiment_groups
{
  if ($num_experiment_groups > 0)
  {
    for (my $i = 1; $i <= $num_experiment_groups; $i++) 
    {
      my $experiment_group_i = $settings{"BJG_experiment_group_$i"};
      my @experiment_names = split(/\;/, $experiment_group_i);
      $num_experiments_in_group_i[$i - 1] = @experiment_names;
    }
  }
}

#---------------------------------------------------------------------------
# clean_experiment_name
#---------------------------------------------------------------------------
sub clean_experiment_name
{
  my $experiment_name = $_[0];
  $experiment_name =~ s/[\"]//g;
  $experiment_name =~ s/[\']//g;
  return $experiment_name;
}

#---------------------------------------------------------------------------
# include_gene
#---------------------------------------------------------------------------
sub include_gene
{
  if ($genes{$_[0]} eq "1") { return 1; }
  else { return 0; }
}

#---------------------------------------------------------------------------
# include_experiment
#---------------------------------------------------------------------------
sub include_experiment
{
  my $experiment = $_[0];

  if ($join_experiments_list eq "ALL" || $experiments{$experiment} eq "1" || $experiment_columns{$experiment} eq "1") { return 1; }
  else { return 0; }
}

#---------------------------------------------------------------------------
# get the gene list
#---------------------------------------------------------------------------
sub load_gene_list
{
  if ($join_genes_list ne "ALL")
  {
	 open(GENES_LIST, "<$join_genes_list") or die "could not open $join_genes_list";

	 my $row_num = 0;
	 my $gene_id = 0;
	 while(<GENES_LIST>)
	 {
		chop;

		my $gene_name = uc $_;
		$gene_name =~ s/[\.]/_/g;
		
		$genes{$gene_name} = "1";
		$gene_ids{$gene_name} = $gene_id;
		$gene_id++;

		$row_num++;
		if ($row_num == $number_from_top) { last; }
	 }
  }
  else
  {
	 my $gene_id = 0;
	 open(EXPRESSIONS, "<$expressions") or die "could not open $expressions";

	 for (my $i = 0; $i < $num_header_rows; $i++) { my $line = <EXPRESSIONS>; }

	 while(<EXPRESSIONS>)
	 {
		chop;

		my @all_values = split(/\t/);

		my @expressions;
		for (my $i = $num_headings; $i < @all_values; $i++) { $expressions[$i - $num_headings] = $all_values[$i]; }
		
		my $gene_name = uc $all_values[$gene_name_location_within_heading - 1];
		$gene_name =~ s/[\.]/_/g;

		$genes{$gene_name} = "1";
		$gene_ids{$gene_name} = $gene_id;
		$gene_id++;
	 }
  }
}

#---------------------------------------------------------------------------
# get the experiment list
#---------------------------------------------------------------------------
sub load_experiment_list
{
  if ($join_experiments_list ne "ALL")
  {
	 open(EXPERIMENTS_LIST, "<$join_experiments_list") or die "could not open $join_experiments_list";

	 while(<EXPERIMENTS_LIST>)
	 {
		chop;

		my $experiment_name = $_;

		$experiments{$experiment_name} = "1";

		print "Adding experiment {$experiment_name} to experiment list\n";
	 }

	 open(EXPRESSIONS, "<$expressions") or die "could not open $expressions";
	 my $line = <EXPRESSIONS>;
	 chop $line;

	 my @all_values = split(/\t/, $line);
	 $num_experiments = @all_values - $num_headings;

	 my $experiment_id = 0;
	 for (my $i = $num_headings; $i < @all_values; $i++)
	 {
		if (include_experiment($all_values[$i]))
		{
		  my $experiment_column = $i - $num_headings;
		  $experiment_columns{"$experiment_column"} = "1";

		  print OUT_EXPERIMENTS $experiment_id . "\t" . clean_experiment_name($all_values[$i]) . "\n";

		  $experiment_ids{$experiment_column} = $experiment_id;
		  $experiment_id++;

		  print "Adding Column experiment {$experiment_column} to experiment columns\n";
		}
	 }
  }
  else
  {
	 my $experiment_id = 0;

	 if ($num_experiment_groups > 0)
	 {
		for (my $i = 1; $i <= $num_experiment_groups; $i++)
		{
		  $experiment_ids{$experiment_id} = $experiment_id;
		  $experiment_id++;

		  print OUT_EXPERIMENTS ($i - 1) . "\t" . clean_experiment_name($settings{"BJG_experiment_group_$i"}) . "\n";
		}
	 }
	 else
	 {
		my @attr_set = get_file_dsc($expressions);
		$num_experiments = @attr_set - $num_headings;
		for (my $i = $num_headings; $i < @attr_set; $i++)
		{
		  my $experiment_name = $attr_set[$i];

		  #$experiment_name = name_to_sql_legal_column_name($experiment_name);

		  $experiments{$experiment_name} = "1";
		  $experiment_ids{$experiment_id} = $experiment_id;
		  $experiment_id++;

		  print OUT_EXPERIMENTS ($i - $num_headings) . "\t" . clean_experiment_name($experiment_name) . "\n";

		  print "Adding experiment {$experiment_name} to experiment list\n";
		}
    }
  }
}

#---------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------
load_experiment_groups;
load_gene_list;
load_experiment_list;

#---------------------------------------------------------------------------
# get the expressions
#---------------------------------------------------------------------------
my $row_num = 0;
my $level_id = 0;
my $printed_headers = 0;
my $remainder;
open(EXPRESSIONS, "<$expressions") or die "could not open $expressions";
while(<EXPRESSIONS>)
{
  chop;

  my @all_values = split(/\t/);

  my @expressions;
  for (my $i = $num_headings; $i < @all_values; $i++) { $expressions[$i - $num_headings] = $all_values[$i]; }

  my $gene_name = uc $all_values[$gene_name_location_within_heading - 1];
  $gene_name =~ s/[\.]/_/g;

  #print "AA$gene_name|AA\n";

  if ($join_format eq "pcluster" && $printed_headers == 0)
  {
    #print "$_ num_experiments=$num_experiments\n";

    print OUT_EXPRESSIONS "gene_name\tgene_name";
    for (my $i = 0; $i < $num_experiments; $i++)
    {
		if (include_experiment($expressions[$i]))
		{
		  print OUT_EXPRESSIONS "\t$expressions[$i]";
		}
    }
    print OUT_EXPRESSIONS "\n";

    $printed_headers = 1;
  }

  if (include_gene($gene_name))
  {
    my $gene_id = $gene_ids{$gene_name};

    if ($join_format eq "sql")
    {
		print OUT_GENES "$gene_id\t$gene_name\n";
    }

    if ($join_format eq "sql")
    {
      if ($num_experiment_groups > 0)
      {
        my $experiment_counter = 0;
        for (my $i = 0; $i < $num_experiment_groups; $i++) 
        {
          print OUT_EXPRESSIONS "$level_id\t$gene_id\t$experiment_ids{$i}\t";

          for (my $j = 0; $j < $num_experiments_in_group_i[$i]; $j++)
          {
				if (include_experiment($experiment_counter))
				{
				  if ($expressions[$experiment_counter] =~ /\S/)
				  {
					 print OUT_EXPRESSIONS "$expressions[$experiment_counter]\t";
				  }
				  else
				  {
					 $num_missing_values++;
					 print OUT_EXPRESSIONS "$missing_value_fill\t";
				  }
				  $experiment_counter++;
				}
          }

          print OUT_EXPRESSIONS "\n";
          $level_id++;
        }
      }
      else
      {
        for (my $i = 0; $i < $num_experiments; $i++)
        {
			 if (include_experiment($i))
			 {
				if ($expressions[$i] =~ /\S/)
				{
				  print OUT_EXPRESSIONS "$level_id\t$gene_id\t$experiment_ids{$i}\t$expressions[$i]\n";
				  $level_id++;
				}
				else
				{
				  $num_missing_values++;
				  if ($missing_value_fill ne "")
				  {
					 print OUT_EXPRESSIONS "$level_id\t$gene_id\t$experiment_ids{$i}\t$missing_value_fill\n";
					 $level_id++;
				  }
				}
          }
        }
      }
    }
    elsif ($join_format eq "pcluster")
    {
      print OUT_EXPRESSIONS "$gene_name\t$gene_name";
      for (my $i = 0; $i < $num_experiments; $i++)
      {
		  if (include_experiment($i))
		  {
			 if ($expressions[$i] =~ /\S/)
			 {
				print OUT_EXPRESSIONS "\t$expressions[$i]";
			 }
			 else
			 {
				$num_missing_values++;
				print OUT_EXPRESSIONS "\t$missing_value_fill";
			 }
		  }
      }
      print OUT_EXPRESSIONS "\n";
    }
  }

  $row_num++;
}

print "Missing Values=" . $num_missing_values . "\n";
