#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

my $TRIPARTITE_GRAPH = "TriPartiteGraph";
my $BNLIKE_GRAPH = "BnLikeGraph";
my $STAT_SUMMARY = "StatsSummary";

my $r = int(rand(100000000));

my $gu_null = "GU___NULL___GU";

my $executable_dir = "$ENV{MYPERLDIR}/lib/SamplePrograms";

#--------------------------------------------------------------------------------
# genexpress_util
#--------------------------------------------------------------------------------
sub genexpress_util
{
  my ($genexpress_file,
      $gene_attribute_file,
      $output_prefix,
      $graph_format,
      $threshold,
      $threshold_min_count,
      $gene_description_file,
      $restricted_gene_list,
      $tripartite_graph,
      $bnlike_graph,
      $stats_summary) = @_;

  open(OUT_FILE, ">tmp.ge_settings.$r");
  print OUT_FILE "GeneXPressFile=$genexpress_file\n\n";
  print OUT_FILE "OutputPrefix=$output_prefix\n\n";
  print OUT_FILE "SignificanceThreshold=$threshold\n\n";
  print OUT_FILE "SignificanceMinCount=$threshold_min_count\n\n";

  print OUT_FILE "OutputFormat=$graph_format\n";

  if ($gene_attribute_file ne $gu_null) { print OUT_FILE "GeneAttributesFile=$gene_attribute_file\n\n"; }

  if ($gene_description_file ne $gu_null) { print OUT_FILE "GeneDescriptionFile=$gene_description_file\n\n"; }
  if ($restricted_gene_list ne $gu_null) { print OUT_FILE "RestrictedGeneList=$restricted_gene_list\n\n"; }

  if ($tripartite_graph)
  {
    copy_file("tmp.ge_settings.$r", "tmp.$r");
    open(GU_FILE, ">>tmp.$r");
    print GU_FILE "GeneXPressUtility=$TRIPARTITE_GRAPH\n\n";
    execute("$executable_dir/genexpress_utils tmp.$r", 1);
    delete_file("tmp.$r");
  }

  if ($bnlike_graph)
  {
    copy_file("tmp.ge_settings.$r", "tmp.$r");
    open(GU_FILE, ">>tmp.$r");
    print GU_FILE "GeneXPressUtility=$BNLIKE_GRAPH\n\n";
    execute("$executable_dir/genexpress_utils tmp.$r", 1);
    delete_file("tmp.$r");
  }

  if ($stats_summary)
  {
    copy_file("tmp.ge_settings.$r", "tmp.$r");
    open(GU_FILE, ">>tmp.$r");
    print GU_FILE "GeneXPressUtility=$STAT_SUMMARY\n\n";
    execute("$executable_dir/genexpress_utils tmp.$r", 1);
    delete_file("tmp.$r");
  }

  delete_file("tmp.ge_settings.$r");
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  genexpress_util($ARGV[0],
		  get_arg("A",    $gu_null, \%args),
		  get_arg("o",    $gu_null, \%args),
		  get_arg("f",    "DottyFormat", \%args),
		  get_arg("S",    0.05, \%args),
		  get_arg("Sc",   1, \%args),
		  get_arg("gd",   $gu_null, \%args),
		  get_arg("g",    $gu_null, \%args),
		  get_arg("3G",  0, \%args),
		  get_arg("BG",   0, \%args),
		  get_arg("SS",   0, \%args));
}
else
{
  print "Usage: genexpress_util.pl genexpress_file\n\n";
  print "      -A <file name>:  External annotation file (default is: yeast.dissect.dat)\n";
  print "      -o <prefix>:     The prefix of the output file to use\n";
  print "      -f <formst>:     Currently supported DottyFormat (default) and TabDelimitedFormat\n";
  print "      -S <threshold>:  Significance Threshold (default is 0.05)\n";
  print "      -Sc <count>:     Significance minimum count (default is 1)\n";
  print "      -gd <file name>: gene description file\n\n";
  print "      -g <file name>:  Restricted gene list to use\n\n";
  print "      -3G:             Print TriPartiteGraph\n";
  print "      -BG:             Print Bn-like graph\n";
  print "      -SS:             Print stats summary file\n\n";
}

