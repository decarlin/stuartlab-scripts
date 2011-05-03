#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------------
# input: 
#    mql - the mysql command
#    database - the name of the database 
#    gene_db_table - the name of the gene db table
#    experiment_db_table - the name of the experiment db table
#    expression_db_table - the name of the expression db table
#    join_expression_experiment_column_expression - how to join expression and experiment from the expression side
#    join_expression_experiment_column_experiment - how to join expression and experiment from the experiment side
#    join_expression_gene_column_expression - how to join expression and gene from the expression side
#    join_expression_gene_column_gene - how to join expression and gene from the gene side
#    gene_label_column - name of the gene column that holds the gene label
#    experiment_label_column - name of the experiment column that holds the experiment label
#    expression_level_column - name of the column that holds the expression value
#    raw_output_file - the name of the output file
# output:
#    a raw data file compiled from the sql database from the expression + gene + experiment tables
#-----------------------------------------------------------------------------------------------------------------

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
$mql = $settings{"mql"};
$database = $settings{"database"};
$gene_db_table = $settings{"gene_db_table"};
$experiment_db_table = $settings{"experiment_db_table"};
$expression_db_table = $settings{"expression_db_table"};
$join_expression_experiment_column_expression = $settings{"join_expression_experiment_column_expression"};
$join_expression_experiment_column_experiment = $settings{"join_expression_experiment_column_experiment"};
$join_expression_gene_column_expression = $settings{"join_expression_gene_column_expression"};
$join_expression_gene_column_gene = $settings{"join_expression_gene_column_gene"};
$gene_label_column = $settings{"gene_label_column"};
$experiment_label_column = $settings{"experiment_label_column"};
$expression_level_column = $settings{"expression_level_column"};
$raw_output_file = $settings{"raw_output_file"};

open(RAW_FILE, ">$raw_output_file");

$exec_str = "$mql -Ne 'select $join_expression_gene_column_expression, $join_expression_experiment_column_expression, $expression_level_column from $expression_db_table' $database > x";
print $exec_str . "\n";
system($exec_str);

open(EXPRESSION, "<x");
while (<EXPRESSION>)
{
  chop;

  ($gene, $experiment, $expression) = split(/\t/, $_, 3);

  $expression_matrix{$gene}{$experiment} = $expression;

  $gene_ids{$gene} = $gene;
  $experiment_ids{$experiment} = $experiment;
}

$exec_str = "$mql -Ne 'select $join_expression_gene_column_gene, $gene_label_column from $gene_db_table' $database > x";
print $exec_str . "\n";
system($exec_str);

open(GENES, "<x");
while (<GENES>)
{
  chop;

  ($gene_id, $gene_name) = split(/\t/, $_, 2);

  $gene_names{$gene_id} = $gene_name;
}

$exec_str = "$mql -Ne 'select $join_expression_experiment_column_experiment, $experiment_label_column from $experiment_db_table' $database > x";
print $exec_str . "\n";
system($exec_str);

open(EXPERIMENTS, "<x");
while (<EXPERIMENTS>)
{
  chop;

  ($experiment_id, $experiment_name) = split(/\t/, $_, 2);

  $experiment_names{$experiment_id} = $experiment_name;
}

print RAW_FILE "Name\tDesc";
foreach $experiment_id (keys(%experiment_ids))
{
  print RAW_FILE "\t$experiment_names{$experiment_id}";
}
print RAW_FILE "\n";

foreach $gene_id (keys(%gene_ids))
{
  print RAW_FILE "$gene_names{$gene_id}\t$gene_names{$gene_id}";
  foreach $experiment_id (keys(%experiment_ids))
  {
	print RAW_FILE "\t$expression_matrix{$gene_id}{$experiment_id}";
  }
  print RAW_FILE "\n";
}
