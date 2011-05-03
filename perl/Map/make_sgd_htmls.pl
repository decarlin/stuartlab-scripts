#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/html_utils.pl";
require "$ENV{MYPERLDIR}/lib/gifinfo.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $const_datasets = "dataset.sgd";
my $const_datasets_groups = "dataset_group.sgd";
my $const_regulators = "regulator.sgd";
my $const_datasets_regulators = "dataset_regulator.sgd";
my $const_feature_dataset_group = "feat_ds_group.sgd";
my $const_go_link = "go_link.sgd";
my $const_motif = "motif.sgd";
my $const_motif_link = "motif_link.sgd";
my $const_gene_names = "$ENV{MYPERLDIR}/lib/data.tab";

my $out_top_level = "index.html";

my $dir = $ARGV[0];

my %args = load_args(\@ARGV);

my $go_max_pvalue = get_arg("gp", 0.01, \%args);
my $motif_max_pvalue = get_arg("mp", 0.01, \%args);

my $r = int(rand(10000));

my %go_component = &read_go_flat_file("$ENV{HOME}/Map/Data/GeneSets/Go/Yeast/component.ontology.flat");
my %go_function = &read_go_flat_file("$ENV{HOME}/Map/Data/GeneSets/Go/Yeast/function.ontology.flat");
my %go_process = &read_go_flat_file("$ENV{HOME}/Map/Data/GeneSets/Go/Yeast/process.ontology.flat");

#--------------------------------------------------------------------------
# Top level html
#--------------------------------------------------------------------------
my @datasets;
my @datasets_descriptions;
my @datasets_urls;
open(DATASETS, "<$dir/$const_datasets");
my $OUT_TOP_LEVEL;
open($OUT_TOP_LEVEL, ">$out_top_level");

&html_header($OUT_TOP_LEVEL);
&html_start_table($OUT_TOP_LEVEL, "cellspacing=\"10\"");

&html_table_row($OUT_TOP_LEVEL, "<br><font face=\"Arial\" size=\"6\" color=\"brown\"><b>Regulator Datasets</b></font><br><br>");

<DATASETS>;
while(<DATASETS>)
{
  chop;
  my @row = split(/\t/);
  $datasets[$row[0]] = lc($row[1]);
  $datasets_descriptions[$row[0]] = $row[2];
  $datasets_urls[$row[0]] = $row[3];

  my $str = &html_link_str($row[2], lc($row[1]) . "/index.html");

  &html_table_row($OUT_TOP_LEVEL, $str);
}

&html_end_table($OUT_TOP_LEVEL);
&html_footer($OUT_TOP_LEVEL);
close($OUT_TOP_LEVEL);

#--------------------------------------------------------------------------
# Read groups per dataset
#--------------------------------------------------------------------------
my @datasets_groups;
open(DATASETS_GROUPS, "<$dir/$const_datasets_groups");
while(<DATASETS_GROUPS>)
{
  chop;

  my @row = split(/\t/);

  $row[1] =~ s/Module[\s]//g;

  $datasets_groups[$row[3]] .= "$row[1]\t";
}

#--------------------------------------------------------------------------
# Read genes per group
#--------------------------------------------------------------------------
my %datasets_groups_features;
open(DATASETS_GROUPS_FEATURES, "<$dir/$const_feature_dataset_group");
<DATASETS_GROUPS_FEATURES>;
while(<DATASETS_GROUPS_FEATURES>)
{
  chop;

  my @row = split(/\t/);

  $row[0] =~ /^([1-9]+)0+([1-9][0-9]+)/;

  my $dataset = $1;
  my $group = $2;

  if (length($datasets_groups_features{$dataset}{$group}) == 0) { $datasets_groups_features{$dataset}{$group} = 0; }
  $datasets_groups_features{$dataset}{$group}++;
}

#--------------------------------------------------------------------------
# Read genes per group
#--------------------------------------------------------------------------
my %datasets_groups_go;
open(DATASETS_GROUPS_GO, "<$dir/$const_go_link");
<DATASETS_GROUPS_GO>;
while(<DATASETS_GROUPS_GO>)
{
  chop;

  my @row = split(/\t/);

  $row[2] =~ /^([1-9]+)0+([1-9][0-9]+)/;

  my $dataset = $1;
  my $group = $2;

  my $go_term = $row[3];
  my $go_association = &get_go_association($go_term);
  my $hits = $row[6];
  my $cluster_size = $row[8];
  my $hits_percent = $cluster_size > 0 ? (100 * $hits / $cluster_size) : 0;
  $hits_percent = format_number($hits_percent, 2);
  my $dataset_count = $row[7];
  my $pvalue = $row[5];

  if ($pvalue <= $go_max_pvalue)
  {
    $datasets_groups_go{$dataset}{$group} .= "$go_term\t$go_association\t$hits\t$hits_percent\t$dataset_count\t$pvalue\n";
    #print "datasets_groups_go{$dataset}{$group}=$datasets_groups_go{$dataset}{$group}\n";
  }
}

#--------------------------------------------------------------------------
# Read Regulators list
#--------------------------------------------------------------------------
my %orf2gene_name;
open(GENE_NAMES, "<$const_gene_names") or die "could not open gene names file $const_gene_names\n";
<GENE_NAMES>;
while(<GENE_NAMES>)
{
  chop;

  my @row = split(/\t/);

  $orf2gene_name{$row[0]} = $row[1];
}

#--------------------------------------------------------------------------
# Read Regulators list
#--------------------------------------------------------------------------
my %regulatorid2regulator;
open(REGULATORS, "<$dir/$const_regulators");
<REGULATORS>;
while(<REGULATORS>)
{
  chop;

  my @row = split(/\t/);

  $regulatorid2regulator{$row[0]} = $row[3];
}

#--------------------------------------------------------------------------
# Read Regulators for each module
#--------------------------------------------------------------------------
my %datasets_groups_regulators;
open(DATASETS_GROUPS_REGULATORS, "<$dir/$const_datasets_regulators");
<DATASETS_GROUPS_REGULATORS>;
while(<DATASETS_GROUPS_REGULATORS>)
{
  chop;

  my @row = split(/\t/);

  $row[1] =~ /^([1-9]+)0+([1-9][0-9]+)/;

  my $dataset = $1;
  my $group = $2;

  my $regulator = $row[2];
  my $depth = $row[4];

  my $orf = $regulatorid2regulator{$regulator};
  my $gene_name = length($orf2gene_name{$orf}) > 0 ? $orf2gene_name{$orf} : $orf;

  $datasets_groups_regulators{$dataset}{$group}{$depth} .= "$gene_name ";
  #print "datasets_groups_regulators{$dataset}{$group}{$depth} .= $regulator\n";
}

#--------------------------------------------------------------------------
# Read genes per group
#--------------------------------------------------------------------------
my %datasets_groups_motif;
my %motifs = &read_motif_file("$dir/$const_motif");
open(DATASETS_GROUPS_MOTIF, "<$dir/$const_motif_link");
<DATASETS_GROUPS_MOTIF>;
while(<DATASETS_GROUPS_MOTIF>)
{
  chop;

  my @row = split(/\t/);

  $row[4] =~ /^([1-9]+)0+([1-9][0-9]+)/;

  my $dataset = $1;
  my $group = $2;

  my $motif_id = $row[1];

  my $motif_str = $motifs{$motif_id};
  my @motif_info = split(/\t/, $motif_str);

  my $motif_name = $motif_info[3];
  my $motif_source = $motif_info[1];
  my $motif_consensus = $motif_info[2];

  my $hits = $row[6];
  my $cluster_size = $row[8];
  my $hits_percent = $cluster_size > 0 ? (100 * $hits / $cluster_size) : 0;
  $hits_percent = format_number($hits_percent, 2);
  my $dataset_count = $row[7];
  my $pvalue = $row[5];

  if ($pvalue <= $motif_max_pvalue)
  {
    $datasets_groups_motif{$dataset}{$group} .= "$motif_name\t$motif_source\t$motif_consensus\t$hits\t$hits_percent\t$dataset_count\t$pvalue\n";
    #print "$dataset\t$motif_name\t$group\t$pvalue\n";
  }
}

#--------------------------------------------------------------------------
# Datasets top level html
#--------------------------------------------------------------------------
for (my $i = 0; $i < @datasets; $i++)
{
  my $dataset = $datasets[$i];
  my $dataset_description = $datasets_descriptions[$i];
  my $dataset_url = $datasets_urls[$i];
  if (length($dataset) > 0)
  {
    system("mkdir -p $dataset");
    system("mkdir -p $dataset/images");

    my $DATASET_TOP_LEVEL;
    open($DATASET_TOP_LEVEL, ">$dataset/index.html");

    &html_header($DATASET_TOP_LEVEL);

    &html_start_table($DATASET_TOP_LEVEL, "cellspacing=\"10\"");

    &html_start_table_row($DATASET_TOP_LEVEL);

    &html_table_column($DATASET_TOP_LEVEL, "<br><font face=\"Arial\" size=\"6\" color=\"brown\"><b>Predicted Regulatory Modules for \u<A HREF=\"$dataset_url\">$dataset_description Analysis</A> dataset</b></font><br><br>");

    &html_table_column($DATASET_TOP_LEVEL, "<A target=\"infowin\" HREF=\"http://genome-www.stanford.edu/Saccharomyces/help/RegModule.html\"><img align=\"right\" valign=\"middle\" alt=\"Help\" border=\"0\" src=\"http://genome-www4.stanford.edu/Saccharomyces/images/help-button.gif\"></A>", "align=\"right\"");

    &html_end_table_row($DATASET_TOP_LEVEL);

    &html_start_table_row($DATASET_TOP_LEVEL);

    &html_table_row($DATASET_TOP_LEVEL, "<font face=\"Times\" size=\"3\">This analysis was performed according to <A HREF=\"http://www.cs.stanford.edu/~eran/module_nets/\">Segal et al.</A> on the pre-existing microarray dataset described above. A <b>regulatory module</b> is comprised of a set of genes predicted to regulate a cluster of genes and the cluster of genes regulated. The predictions are based on the co-expression of the regulators and those genes being regulated (see <A HREF=\"http://www.cs.stanford.edu/~eran/module_nets/\">Segal et al.</A>). For each module, the GO annotations (assigned by SGD) were analyzed to find common processes, functions, or cellular components shared by the gene products in a module (both regulators and regulatees). In addition, the upstream intergenic regions of each gene in a module were examined to find potential regulatory motifs.", "colspan=\"2\"");

    &html_table_row($DATASET_TOP_LEVEL, "<br><hr width=75%><br>", "colspan=\"2\"");

    &html_table_row($DATASET_TOP_LEVEL, "<font face=\"Times\" size=\"3\">More regulators, GO terms, motifs, binding factors, and regulated genes can be found on individual module pages. The module numbers (Module No.) in the table below correspond to the modules (separated by horizontal white lines) shown in the Bird's Eye View image on the left.<br><br>", "colspan=\"2\"");

    &html_end_table($DATASET_TOP_LEVEL);

    my $gif_width = &get_gif_width("$dir/images$i/birdseye.gif");
    my $gif_height = &get_gif_height("$dir/images$i/birdseye.gif");

#    system("cp $dir/images$i/birdseye.gif $dataset/images/");

    open(TMP, ">tmp.$r");
    my @row = split(/\t/, $datasets_groups[$i]);
    for (my $j = 0; $j < @row; $j++)
    {
#      system("cp $dir/images$i/cluster_$row[$j].gif $dataset/images/");
      print TMP "$datasets_groups_features{$i}{$row[$j]}\tcluster_$row[$j].html\n";
    }

    print "create_image_map.pl tmp.$r -w $gif_width -h $gif_height -i images/birdseye.gif -t module_win\n";
    my $image_map = `create_image_map.pl tmp.$r -w $gif_width -h $gif_height -i images/birdseye.gif -t module_win`;

    &html_start_table($DATASET_TOP_LEVEL, "");


    &html_start_table_column($DATASET_TOP_LEVEL, "valign=\"top\"");

    &html_start_table($DATASET_TOP_LEVEL, "cellspacing=\"0\" border=\"1\"");

    &html_table_row($DATASET_TOP_LEVEL, "<b>Bird's Eye View</b><br>(modules are in rows, colors are <font color=\"red\"><b>induced</b></font> and <font color=\"green\"><b>repressed</b></font>", "align=\"middle\" bgcolor=\"#DDE9EC\"");

    &html_table_row($DATASET_TOP_LEVEL, $image_map);

    &html_end_table($DATASET_TOP_LEVEL);

    &html_end_table_column($DATASET_TOP_LEVEL);


    &html_start_table_column($DATASET_TOP_LEVEL, "valign=\"top\"");

    &html_start_table($DATASET_TOP_LEVEL, "width=\"100%\" border=\"1\" cellpadding=\"5\" cellspacing=\"1\"");

    &html_start_table_row($DATASET_TOP_LEVEL, "bgcolor=\"#DDE9EC\"");

    &html_table_column_style($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">Module No.", "align=\"center\"");
    &html_table_column_style($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">Top Regulator in Module", "align=\"center\"");
    &html_table_column_style($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">Top Significant GO term for Regulated Genes in Module.", "align=\"center\"");
    &html_table_column_style($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">Top Significant Motif", "align=\"center\"");
    &html_table_column_style($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">Motif Binding Factor", "align=\"center\"");

    &html_end_table_row($DATASET_TOP_LEVEL);

    my @row = split(/\t/, $datasets_groups[$i]);
    for (my $j = 0; $j < @row; $j++)
    {
      my $module = $row[$j];
      my $cluster_num = $j + 1;
      my $cluster_size = $datasets_groups_features{$i}{$module};

      &html_start_table_row($DATASET_TOP_LEVEL);

      &html_table_column($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\"><A target=module_win HREF=\"cluster_$module.html\">$cluster_num</A>", "align=\"center\"");
      &html_table_column($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">$datasets_groups_regulators{$i}{$module}{0}", "align=\"center\"");
      my @go_terms = split(/\n/, $datasets_groups_go{$i}{$module});
      my @go_row = split(/\t/, $go_terms[0]);
      &html_table_column($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">$go_row[0]", "align=\"center\"");

      my $motif = "";
      my $motif_consensus = "";
      my $motif_pvalue = 1;
      my @motif_terms = split(/\n/, $datasets_groups_motif{$i}{$module});
      for (my $k = 0; $k < @motif_terms; $k++)
      {
	my @motif_row = split(/\t/, $motif_terms[$k]);

	if ($motif_row[6] < $motif_pvalue)
	{
	  $motif_pvalue = $motif_row[6];
	  $motif = $motif_row[0];
	  $motif_consensus = lc($motif_row[2]);
	}
      }
      &html_table_column($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">$motif_consensus", "align=\"center\"");
      &html_table_column($DATASET_TOP_LEVEL, "<font face=\"times\" size=\"-1>\">$motif", "align=\"center\"");

      &html_end_table_row($DATASET_TOP_LEVEL);
    }

    &html_end_table($DATASET_TOP_LEVEL);

    &html_end_table_column($DATASET_TOP_LEVEL);


    &html_end_table($DATASET_TOP_LEVEL);

    &html_footer($DATASET_TOP_LEVEL);
    close($DATASET_TOP_LEVEL);

    system("rm -f tmp.$r");
  }
}

#--------------------------------------------------------------------------
# Modules htmls
#--------------------------------------------------------------------------
for (my $i = 0; $i < @datasets; $i++)
{
  my $dataset = $datasets[$i];
  my $dataset_description = $datasets_descriptions[$i];
  my $dataset_url = $datasets_urls[$i];
  if (length($dataset) > 0)
  {
    my @row = split(/\t/, $datasets_groups[$i]);
    for (my $j = 0; $j < @row; $j++)
    {
      my $module = $row[$j];
      my $cluster_num = $j + 1;
      my $cluster_size = $datasets_groups_features{$i}{$module};

      my $MODULE_HTML;
      open($MODULE_HTML, ">$dataset/cluster_$module.html");

      &html_header($MODULE_HTML);

      &html_start_table($MODULE_HTML, "cellspacing=\"10\" width=\"100%\"");
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\"><br><font face=\"Arial\" size=\"6\" color=\"brown\"><b>Module $cluster_num ($cluster_size Genes)</b> - <A HREF=\"$dataset_url\">\u$dataset_description Analysis</A></font>");
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\"><A Name=\"program\">Jump to: <A HREF=\"cluster_$module.html#GO\">Significant GO annotations</A> | <A HREF=\"cluster_$module.html#motifs\">Significant Motif Binding Sites</A>.");
      &html_end_table($MODULE_HTML);

      #----------------------------------------------------
      # Control Program
      #----------------------------------------------------
      &html_start_table($MODULE_HTML, "cellspacing=\"3\" cellpadding=\"4\" border=\"1\" width=\"100%\"");
      &html_freestyle($MODULE_HTML, "<tr bgcolor=\"lightgrey\"><th align=\"left\"><font face=\"Arial\" size=\"3\">Predicted Regulatory Module</th></tr>\n");
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\">The control program is a set of gene products predicted to regulate the cluster of genes below. The prediction is based on the relationship between the expression of the regulator and the expression of genes in the cluster as described in Segal et al. In several instances, there is direct experimental evidence to corroborate the predicted function of the regulators. In this view, the regulators (circled gene products) are in a hierarchy according to their effects on gene expression in the experiments directly below them.", " colspan=\"6\"");
      &html_end_table($MODULE_HTML);

      &html_start_table($MODULE_HTML);
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\"><img src=\"images/cluster_$module.gif\" border=\"0\"><br><br>", "colspan=\"6\"");
      &html_end_table($MODULE_HTML);

      #----------------------------------------------------
      # GO
      #----------------------------------------------------
      &html_start_table($MODULE_HTML);
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\"><A Name=\"GO\">Jump to: <A HREF=\"cluster_$module.html#program\">Predicted Control Program</A> | <A HREF=\"cluster_$module.html#motifs\">Significant Motif Binding Sites</A>.");
      &html_table_row($MODULE_HTML, "&nbsp<br>");
      &html_end_table($MODULE_HTML);

      &html_start_table($MODULE_HTML, "cellspacing=\"3\" cellpadding=\"4\" border=\"1\"");
      &html_freestyle($MODULE_HTML, "<tr><th colspan=\"6\" align=\"left\" bgcolor=\"lightgrey\"><font face=\"Arial\" size=\"3\">Significant GO Annotations</font></th></tr>\n");
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\">This table lists, in order of significance, all GO annotations enriched in this cluster at a pvalue below 0.01. For each significant GO annotation, this table displays the following statistics: the number of genes in the cluster with the annotation (<b>Hits</b>), the percentage of genes in the cluster with the annotation (<b>Hits (%)</b>), the total number of genes in the entire dataset with the annotation (<b>Total</b>) and the <b>pvalue</b> of the annotation enrichment.", " colspan=\"6\"");

      &html_start_table_row($MODULE_HTML);
      &html_table_column($MODULE_HTML, "<b>GO Term</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Ontology</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Hits</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Hits (%)</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Total</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Pvalue</b>", "bgcolor=\"lightgrey\"");
      &html_end_table_row($MODULE_HTML);

      my @go_terms = split(/\n/, $datasets_groups_go{$i}{$module});
      for (my $k = 0; $k < @go_terms; $k++)
      {
	my @go_row = split(/\t/, $go_terms[$k]);

	my $go_color = &get_go_color($go_row[1]);

	&html_start_table_row($MODULE_HTML, "bgcolor=\"$go_color\"");

	for (my $n = 0; $n < @go_row; $n++)
	{
	  &html_table_column($MODULE_HTML, $go_row[$n]);
	}

	&html_end_table_row($MODULE_HTML);
      }
      &html_end_table($MODULE_HTML);

      &html_new_line($MODULE_HTML);
      &html_new_line($MODULE_HTML);

      #----------------------------------------------------
      # Motifs
      #----------------------------------------------------
      &html_start_table($MODULE_HTML);
      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\"><A Name=\"motifs\">Jump to: <A HREF=\"cluster_$module.html#program\">Predicted Control Program</A> | <A HREF=\"cluster_$module.html#GO\">Significant GO Annotations</A>.");
      &html_table_row($MODULE_HTML, "&nbsp<br>");
      &html_end_table($MODULE_HTML);

      &html_start_table($MODULE_HTML, "cellspacing=\"3\" cellpadding=\"4\" border=\"1\"");
      &html_freestyle($MODULE_HTML, "<tr><th colspan=\"7\" align=\"left\" bgcolor=\"lightgrey\"><font face=\"Arial\" size=\"3\">Significant Motif Binding Sites</font></th></tr>\n");

      &html_table_row($MODULE_HTML, "<font face=\"Arial\" size=\"2\">This table lists, in order of significance, all motif binding sites enriched in this cluster at a pvalue below 0.01. For each significant motif binding site, the following statistics are displayed: the number of genes in the cluster with the binding site in their promoter (<b>Hits</b>), the percentage of genes with the binding site in their promoter (<b>Hits (%)</b>), the total number of genes in the dataset with the binding site in their promoter (<b>Total</b>) and the <b>pvalue</b> of the binding site enrichment. To view the sequence logo for each motif, click on the motif name.</font>", " colspan=\"7\"");

      &html_start_table_row($MODULE_HTML);
      &html_table_column($MODULE_HTML, "<b>Motif</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Source</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Consensus</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Hits</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Hits (%)</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Total</b>", "bgcolor=\"lightgrey\"");
      &html_table_column($MODULE_HTML, "<b>Pvalue</b>", "bgcolor=\"lightgrey\"");
      &html_end_table_row($MODULE_HTML);

      my @motif_terms = split(/\n/, $datasets_groups_motif{$i}{$module});
      for (my $k = 0; $k < @motif_terms; $k++)
      {
	&html_start_table_row($MODULE_HTML);

	my @motif_row = split(/\t/, $motif_terms[$k]);
	for (my $n = 0; $n < @motif_row; $n++)
	{
	  if ($n == 0)
	  {
	    my $motif_link = "$motif_row[$n]";
	    &html_table_column($MODULE_HTML, "<A target=\"motifs\" HREF=\"../images/$motif_link.gif\">$motif_row[$n]</A>");
	  }
	  else
	  {
	    &html_table_column($MODULE_HTML, $motif_row[$n]);
	  }
	}

	&html_end_table_row($MODULE_HTML);
      }
      &html_end_table($MODULE_HTML);

      &html_footer($MODULE_HTML);
      close($MODULE_HTML);
    }
  }
}

#--------------------------------------------------------------------------
# For reading which attributes are which in the GO Hierarchy
#--------------------------------------------------------------------------
sub read_go_flat_file
{
  my ($file) = @_;

  my %res;

  open(INFILE, "<$file");
  while(<INFILE>)
  {
    chop;

    my @row = split(/\t/);

    $res{$row[1]} = "1";
  }

  return %res;
}

sub get_go_association
{
  my ($go_term) = @_;

  if ($go_component{$go_term} eq "1") { return "Cellular Component"; }
  elsif ($go_function{$go_term} eq "1") { return "Molecular Function"; }
  elsif ($go_process{$go_term} eq "1") { return "Biological Process"; }
  else { return ""; }
}

#--------------------------------------------------------------------------
# For reading which attributes are which in the GO Hierarchy
#--------------------------------------------------------------------------
sub read_motif_file
{
  my ($file) = @_;

  my %res;

  open(MOTIF_FILE, "<$file");
  while(<MOTIF_FILE>)
  {
    chop;

    my @row = split(/\t/);

    $res{$row[0]} = $_;
  }

  return %res;
}

#--------------------------------------------------------------------------
# GO color
#--------------------------------------------------------------------------
sub get_go_color
{
  my ($color) = @_;

  if ($color eq "Cellular Component") { return "azure"; }
  elsif ($color eq "Biological Process") { return "lightyellow"; }
  elsif ($color eq "Molecular Function") { return "lavenderblush"; }
  else { return "azure"; }
}


__DATA__

make_sgd_htmls.pl <dir>

   Given an SGD version directory, creates all the html files necessary

   -gp <num>: cutoff pvalue for all GO associations (default 0.01)
   -mp <num>: cutoff pvalue for all motif associations (default 0.001)

