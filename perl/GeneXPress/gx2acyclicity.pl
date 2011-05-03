#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/format_number.pl";

my $r = rand(int(100000));

my $G_NULL = "__G_NULL__";
my $mql = "/u/erans/mysql/mysql-3.23.41-pc-linux-gnu-i686/bin/mysql";

my $verbose = 1;

my $STATUS_CLUSTERS = 0;
my $STATUS_SPLITS_TO_CLUSTERS = 1;

my %gene_to_unique_id;

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub load_gene_to_unqiue_id_map
{
  my ($gene_table, $database) = @_;

  execute("$mql -e 'select gene_id, gene_name from $gene_table' $database > gene_select.$r", $verbose);

  open(INFILE, "<gene_select.$r");
  while(<INFILE>)
  {
    chop;

    my @row = split(/\t/);

    $gene_to_unique_id{$row[1]} = $row[0];
  }

  delete_file("gene_select.$r");
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub make_acyclicity_file
{
  my ($file, $attribute, $print_attribute, $gene_table, $output_file) = @_;

  my $status;

  my %clusters_ids_to_g_clusters;

  my $min_value = 100000;
  my $max_value = -100000;

  open(OUTFILE, ">$output_file");
  open(INFILE, "<$file");
  while(<INFILE>)
  {
    chop;

    if ($_ eq "Clusters") { $status = $STATUS_CLUSTERS; }
    elsif ($_ eq "SplitsToClusters") { $status = $STATUS_SPLITS_TO_CLUSTERS; }
    elsif ($_ !~ /========/ && length($_) > 0)
    {
      if ($status == $STATUS_CLUSTERS)
      {
	my @row = split(/\t/);

	my $cluster_id = $row[0];

	for (my $i = 1; $i < @row; $i++)
	{
	  if ($row[$i] =~ /$attribute[\s]=[\s][\{](.*)[\}]/)
	  {
	    $clusters_ids_to_g_clusters{$cluster_id} = $1;

	    my @values = split(/\;/, $1);
	    for (my $j = 0; $j < @values; $j++)
	    {
	      if ($values[$j] < $min_value) { $min_value = $values[$j]; }
	      if ($values[$j] > $max_value) { $max_value = $values[$j]; }
	    }
	  }
	}
      }
      elsif ($status == $STATUS_SPLITS_TO_CLUSTERS)
      {
	my %disallowed_cluster_values;
	my $num_disallowed_cluster_values = 0;

	my @row = split(/\t/);

	for (my $i = 1; $i < @row; $i++)
	{
	  my $cluster_id = $row[$i];
	  my @values = split(/\;/, $clusters_ids_to_g_clusters{$cluster_id});
	  for (my $j = 0; $j < @values; $j++)
	  {
	    my $disallow_cluster = $values[$j] - $min_value;
	    if ($disallowed_cluster_values{$disallow_cluster} ne "1")
	    {
	      $disallowed_cluster_values{$disallow_cluster} = "1";	
	      $num_disallowed_cluster_values++;
	    }
	  }
	}

	my $num_values = $max_value - $min_value + 1;
	my $remaining_prob = 1 / ($num_values - $num_disallowed_cluster_values);

	if (length($gene_to_unique_id{$row[0]}) > 0)
	{
	  print OUTFILE "$gene_table\t$print_attribute\t$gene_to_unique_id{$row[0]}\t$num_values\t";

	  $remaining_prob = format_number($remaining_prob, 5);

	  for (my $i = 0; $i < $num_values; $i++)
	  {
	    if ($disallowed_cluster_values{$i} eq "1") { print OUTFILE "0\t"; }
	    else { print OUTFILE "$remaining_prob\t"; }
	  }
	  print OUTFILE "\n";
	}
      }
    }
  }
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub create_acyclicity_file
{
  my ($gx_file, $gene_table, $database, $attribute, $print_attribute, $output_file) = @_;

  my $new_gx_file = "$gx_file.$r";

  execute("cp $gx_file $new_gx_file", $verbose);

  execute("create_genexpress_cluster_lists.pl $new_gx_file -Add", $verbose);

  execute("java -jar $ENV{HOME}/develop/GeneXPress/src/release/GeneXPress.jar $new_gx_file -a Acyclicity -c Modules -o tmp_$r.acyclicity", $verbose);

  load_gene_to_unqiue_id_map($gene_table, $database);

  make_acyclicity_file("tmp_$r.acyclicity", $attribute, $print_attribute, $gene_table, $output_file);

  delete_file("tmp_$r.gxc");
  delete_file("modules.$r");
  delete_file("tmp_$r.acyclicity");
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  create_acyclicity_file($ARGV[0],
			 get_arg("g", $G_NULL, \%args),
			 get_arg("d", $G_NULL, \%args),
			 get_arg("a", "g_cluster", \%args),
			 get_arg("p", "g_cluster", \%args),
			 get_arg("o", $G_NULL, \%args));
}
else
{
  print STDOUT <DATA>;
}

__DATA__

Usage: gx2acyclicity.pl 

          -g <gene table>: the name of the gene table
          -d <database>:   the name of the database
          -a <attribute>:  the name of the attribute (default is g_cluster)
          -p <attribute>:  the name of the attribute to print (default is g_cluster)
          -o <file>:       the name of the output file to print to

