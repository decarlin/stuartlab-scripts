#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------
# input: 
#    prefix - the prefix of the files we're using
#    web_dir - the web directory to copy to
#    web_description - the description of the current run
#    web_project_title - the title of the entire project
#    web_project_description - the description of the entire project
#    iteration - the iteration number
#    gene_table - the name of the main gene table we're using
#
# output:
#    copies the files under a web directory and makes a html file for it
#
#-----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_names_for_dir.pl";
require "$ENV{MYPERLDIR}/lib/format_number.pl";

my %settings = load_settings($ARGV[0]);

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $web_dir = $settings{"web_dir"};

my $gene_table = $settings{"gene_table"};

my $motifs_dir = "$web_dir/$gene_table/motifs";

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"iteration"}; }
my $next_iteration = $iteration + 1;

my $r = int(rand 1000000000);
my $verbose = 1;

#---------------------------------------------
# DEFINES
#---------------------------------------------
my $GeneXPress = "GeneXPress";
my $GeneXPress_EXT = "tsc";

my $GeneClusterReport = "GeneClusterReport";
my $GeneClusterReport_EXT = "tsc-geneclusters.html";
my $ArrayClusterReport = "ArrayClusterReport";
my $ArrayClusterReport_EXT = "tsc-arrayclusters.html";
my $RGenesReport = "RGenesReport";
my $RGenesReport_EXT = "tsc-rgenes-report.html";
my $EGenesReport = "EGenesReport";
my $EGenesReport_EXT = "tsc-egenes-report.html";
my $ModuleListReport = "ModuleListReport";
my $ModuleListReport_EXT = "tsc-modulelist.html";
my $HTMLReport = "ModuleListReport";
my $HTMLReport_EXT = "tsc-grouping*.html";

my $Motifs = "Motifs";
my $Motifs_EXT = "pssm";

my $ThreeTierGraph = "3TierGraph";
my $ThreeTierGraph_EXT = "3tier.dotty";
my $BnGraph = "BnGraph";
my $BnGraph_EXT = "bn.dotty";
my $StatSummary = "StatSummary";
my $StatSummary_EXT = "sum";

my $Net = "Net";
my $Net_EXT = "net";

my $Settings = "Settings";

my $WebDescription = "Description";

my $Changes = "Changes";
my $Changes_EXT = "stats";

my $Cor = "Cor";
my $Cor_EXT = "cor.dat";

my $MaxCor = "MaxCor";
my $MaxCor_EXT = "max_cor.dat";

my $LL = "TestSet";
my $LLEXT = "out.ll";

#---------------------------------------------
# SETTINGS STUFF
#---------------------------------------------
my $web_project_title = $settings{"web_project_title"};

my %full_html_dsc;
my %max_iteration_for_runs;
my %web_descriptions;
$web_descriptions{$gene_table} = $settings{"web_description"};

my $web_project_description = $settings{"web_project_description"};

open(NEW_HTML, ">$web_dir/index.$r.html");

my $settings_file = "$gene_table.full";
my $genexpress_file = "${prefix}_l$iteration.$GeneXPress_EXT";

my $gene_cluster_report_file = "${prefix}_l$iteration.$GeneClusterReport_EXT";
my $array_cluster_report_file = "${prefix}_l$iteration.$ArrayClusterReport_EXT";
my $rgenes_report_file = "${prefix}_l$iteration.$RGenesReport_EXT";
my $egenes_report_file = "${prefix}_l$iteration.$EGenesReport_EXT";
my $modulelist_report_file = "${prefix}_l$iteration.$ModuleListReport_EXT";
my $html_report_file = "${prefix}_l$iteration.$HTMLReport_EXT";

my $threetiergraph_file = "${prefix}_l$iteration.$ThreeTierGraph_EXT";
my $bngraph_file = "${prefix}_l$iteration.$BnGraph_EXT";
my $stat_summary_file = "${prefix}_l$iteration.$StatSummary_EXT";

my $motifs_file = "*.$Motifs_EXT";
my $net_file = "${prefix}_l$iteration.$Net_EXT";
my $cor_file = "$gene_table.$Cor_EXT.$iteration";
my $max_cor_file = "$gene_table.$MaxCor_EXT.$iteration";
my $attribute_changes_file = "${prefix}_$iteration.$Changes_EXT";
my $test_set_ll_file = "test_${prefix}_$iteration.$LLEXT";

my $has_motifs = 0;
my @all_motif_files = <$dir/out/motifs/*.pssm>;
if (@all_motif_files > 0) { $has_motifs = 1; }

#------------------------------------------------------------------------------------
# get_iteration_dsc
#------------------------------------------------------------------------------------
sub get_test_set_ll
{
  execute("grep exp_level $_[0] | cut -f3 > tmp.$r");

  open(TMP, "<tmp.$r");

  my $ll = <TMP>;
  chop $ll;

  delete_file("tmp.$r");

  return $ll;
}

#------------------------------------------------------------------------------------
# get_attribute_in_file
#------------------------------------------------------------------------------------
sub get_attribute_in_file
{
  execute("grep $_[1] $_[0] | cut -f$_[2] > tmp.$r");

  open(TMP, "<tmp.$r");

  my $attribute = <TMP>;
  chop $attribute;

  delete_file("tmp.$r");

  return $attribute;
}

#------------------------------------------------------------------------------------
# get_iteration_dsc
#------------------------------------------------------------------------------------
sub copy_files_to_web
{
  create_dir("$web_dir");
  create_dir("$web_dir/$gene_table");

  my $settings_path = "$settings_file";
  my $genexpress_path = "$dir/out/$genexpress_file";

  my $gene_cluster_report_path = "$dir/out/$gene_cluster_report_file";
  my $array_cluster_report_path = "$dir/out/$array_cluster_report_file";
  my $rgenes_report_path = "$dir/out/$rgenes_report_file";
  my $egenes_report_path = "$dir/out/$egenes_report_file";
  my $modulelist_report_path = "$dir/out/$modulelist_report_file";
  my $html_report_path = "$dir/out/$html_report_file";

  my $threetiergraph_path = "$dir/out/$threetiergraph_file";
  my $bngraph_path = "$dir/out/$bngraph_file";
  my $stat_summary_path = "$dir/out/$stat_summary_file";

  my $motifs_path = "$dir/out/motifs/$motifs_file";
  my $net_path = "$dir/out/$net_file";
  my $cor_path = "$dir/out/$cor_file";
  my $max_cor_path = "$dir/out/$max_cor_file";
  my $attribute_changes_path = "$dir/out/$attribute_changes_file";
  my $test_set_ll_path = "$dir/out/$test_set_ll_file";

  copy_file("$settings_path", "$web_dir/$gene_table");

  copy_file("$genexpress_path", "$web_dir/$gene_table");
  delete_file("$web_dir/$gene_table/$genexpress_file.gz");
  execute("cd $web_dir/$gene_table; gzip $genexpress_file");
  copy_file("$genexpress_path", "$web_dir/$gene_table");

  copy_file("$gene_cluster_report_path", "$web_dir/$gene_table");
  copy_file("$array_cluster_report_path", "$web_dir/$gene_table");
  copy_file("$rgenes_report_path", "$web_dir/$gene_table");
  copy_file("$egenes_report_path", "$web_dir/$gene_table");
  copy_file("$modulelist_report_path", "$web_dir/$gene_table");
  execute("cp $html_report_path $web_dir/$gene_table");

  copy_file("$threetiergraph_path", "$web_dir/$gene_table");
  copy_file("$bngraph_path", "$web_dir/$gene_table");
  copy_file("$stat_summary_path", "$web_dir/$gene_table");

  copy_file("$net_path", "$web_dir/$gene_table");
  copy_file("$cor_path", "$web_dir/$gene_table");
  copy_file("$max_cor_path", "$web_dir/$gene_table");
  copy_file("$attribute_changes_path", "$web_dir/$gene_table");
  copy_file("$test_set_ll_path", "$web_dir/$gene_table");
}

#------------------------------------------------------------------------------------
# clean_dsc_file
#------------------------------------------------------------------------------------
sub clean_dsc_file
{
  my $dsc_file = "${web_dir}/$prefix.dsc";

  if (file_exists($dsc_file))
  {
	 open(TMP_DSC_FILE, ">$dsc_file.$r");

	 open(DSC_FILE, "<$dsc_file");

	 my $current_run = "";
	 while(<DSC_FILE>)
	 {
		chop;

		my ($key, $value) = split(/[\=]/);

		if ($key eq "run") { $current_run = $value; }
		
		if ($current_run eq $gene_table && $key eq "iteration")
		{
		  my @vals = split(/\,/, $value);

		  if ($vals[0] != $next_iteration) { print TMP_DSC_FILE "$_\n"; }
		}
		else
		{
		  if ($current_run ne $gene_table || $key ne "description")
		  {
			 print TMP_DSC_FILE "$_\n";
		  }
		}
	 }

	 move_file("$dsc_file.$r", "$dsc_file");
  }
}

#------------------------------------------------------------------------------------
# get_iteration_dsc
#------------------------------------------------------------------------------------
sub get_iteration_dsc
{
  my $res = "$next_iteration";

  if (file_exists("$web_dir/$gene_table/$settings_file")) { $res .= ",$Settings;$gene_table/$settings_file"; }

  if (file_exists("$web_dir/$gene_table/$genexpress_file")) { $res .= ",$GeneXPress;$gene_table/$genexpress_file"; }

  if (file_exists("$web_dir/$gene_table/$gene_cluster_report_file")) { $res .= ",$GeneClusterReport;$gene_table/$gene_cluster_report_file"; }
  if (file_exists("$web_dir/$gene_table/$array_cluster_report_file")) { $res .= ",$ArrayClusterReport;$gene_table/$array_cluster_report_file"; }
  if (file_exists("$web_dir/$gene_table/$rgenes_report_file")) { $res .= ",$RGenesReport;$gene_table/$rgenes_report_file"; }
  if (file_exists("$web_dir/$gene_table/$egenes_report_file")) { $res .= ",$EGenesReport;$gene_table/$egenes_report_file"; }
  if (file_exists("$web_dir/$gene_table/$modulelist_report_file")) { $res .= ",$ModuleListReport;$gene_table/$modulelist_report_file"; }
  if (file_exists("$web_dir/$gene_table/$html_report_file")) { $res .= ",$HTMLReport;$gene_table/$html_report_file"; }

  if (file_exists("$web_dir/$gene_table/motifs/motifs_$next_iteration.html")) { $res .= ",$Motifs;$gene_table/motifs/motifs_$next_iteration.html"; }

  if (file_exists("$web_dir/$gene_table/$net_file")) { $res .= ",$Net;$gene_table/$net_file"; }

  if (file_exists("$web_dir/$gene_table/$threetiergraph_file")) { $res .= ",$ThreeTierGraph;$gene_table/$threetiergraph_file"; }
  if (file_exists("$web_dir/$gene_table/$bngraph_file")) { $res .= ",$BnGraph;$gene_table/$bngraph_file"; }
  if (file_exists("$web_dir/$gene_table/$stat_summary_file")) { $res .= ",$StatSummary;$gene_table/$stat_summary_file"; }

  if (file_exists("$web_dir/$gene_table/$cor_file")) { $res .= ",$Cor;$gene_table/$cor_file"; }

  if (file_exists("$web_dir/$gene_table/$max_cor_file")) { $res .= ",$MaxCor;$gene_table/$max_cor_file"; }

  if (file_exists("$web_dir/$gene_table/$attribute_changes_file")) { $res .= ",$Changes;$gene_table/$attribute_changes_file"; }

  if (file_exists("$web_dir/$gene_table/$test_set_ll_file")) { $res .= ",$LL;" . get_test_set_ll("$web_dir/$gene_table/$test_set_ll_file"); }

  return $res;
}

#------------------------------------------------------------------------------------
# get_iteration_dsc_hash
#------------------------------------------------------------------------------------
sub parse_iteration_dsc
{
  my $current_run = $_[0];
  my $iteration_str = $_[1];

  my %res;

  my @iteration_dsc = split(/\,/, $iteration_str);

  my $iteration_num = $iteration_dsc[0];

  my $counter = $max_iteration_for_runs{$current_run};
  if (length($counter) == 0 || $iteration_num > $counter) { $max_iteration_for_runs{$current_run} = $iteration_num; }

  for (my $i = 1; $i < @iteration_dsc; $i++)
  {
    my ($key, $value) = split(/\;/, $iteration_dsc[$i]);

    $full_html_dsc{"$current_run.$iteration_num.$key"} = $value;

    #print "full_html_dsc{$current_run.$iteration_num.$key} = " . $full_html_dsc{"$current_run.$iteration_num.$key"} . "\n";
  }
}

#------------------------------------------------------------------------------------
# print_file_link
#------------------------------------------------------------------------------------
sub print_link
{
  my $text = $_[0];
  my $link = $_[1];

  print NEW_HTML "<a href=\"$link\">$text</a>\n";
}

#------------------------------------------------------------------------------------
# print_file_link
#------------------------------------------------------------------------------------
sub print_file_link
{
  my $current_run = $_[0];
  my $file_types = $_[1];
  my $link = $_[2];

  my $max_iteration = $max_iteration_for_runs{$current_run};

  my $first = 1;
  for (my $i = 1; $i <= $max_iteration; $i++)
  {
	 my $key = $full_html_dsc{"$current_run.$i.$file_types"};

	 if (length($key) > 0)
	 {
		if ($first == 1)
		{
		  $first = 0;

		  if ($link eq "true") { print NEW_HTML "<tr><td colspan=2><br><font size=3><b>$file_types Files:</b>\n"; }
		  else { print NEW_HTML "<tr><td colspan=2><br><font size=3><b>$file_types:</b>\n"; }
		}

		if ($link eq "true")
		{
		  print NEW_HTML "&nbsp;<a href=\"$key\"><font size=3>$i</a>\n";
		  if ($file_types eq $GeneXPress)
		  {
			 print NEW_HTML "<a href=\"$key.gz\"><font size=1>($i)</a>\n";
		  }
		}
		else { print NEW_HTML "&nbsp;$i: $key\n"; }
	 }
  }

  if ($first == 0) { print NEW_HTML "</td></tr>\n"; }
}

#------------------------------------------------------------------------------------
# print_iteration
#------------------------------------------------------------------------------------
sub print_run
{
  my $current_run = $_[0];

  print NEW_HTML "<tr><td>&nbsp;</td></tr>\n";

  print NEW_HTML "<tr class=\"oddLine\"><td colspan=2><font size=4><A name=\"$current_run\">$current_run</td></tr>\n";

  print NEW_HTML "<tr><td colspan=2><br><table><tr><td><font size=3><b>Description:</b></td><td><font size=3>$web_descriptions{$current_run}</td></tr></table></td></tr>\n";

  my $settings_key = "$current_run.$max_iteration_for_runs{$current_run}.$Settings";
  print NEW_HTML "<tr><td colspan=2><br><font size=3><b><a href=\"$full_html_dsc{$settings_key}\">Parameter File</a></b></td></tr>\n";

  print_file_link($current_run, $GeneXPress, "true");

  print_file_link($current_run, $GeneClusterReport, "true");
  print_file_link($current_run, $ArrayClusterReport, "true");
  print_file_link($current_run, $RGenesReport, "true");
  print_file_link($current_run, $EGenesReport, "true");
  print_file_link($current_run, $ModuleListReport, "true");

  print_file_link($current_run, $Motifs, "true");

  print_file_link($current_run, $Net, "true");

  print_file_link($current_run, $StatSummary, "true");

  print_file_link($current_run, $ThreeTierGraph, "true");

  print_file_link($current_run, $BnGraph, "true");

  print_file_link($current_run, $LL, "false");

  print_file_link($current_run, $Cor, "true");

  print_file_link($current_run, $MaxCor, "true");

  print_file_link($current_run, $Changes, "true");

  print NEW_HTML "\n";
}

#------------------------------------------------------------------------------------
# update_description
#------------------------------------------------------------------------------------
sub update_description
{
  my $dsc_file = "${web_dir}/$prefix.dsc";

  open(TMP_DSC_FILE, ">$dsc_file.$r");

  my $printed_line = 0;

  if (file_exists($dsc_file))
  {
	 open(DSC_FILE, "<$dsc_file");

	 my $current_run = "";
	 while(<DSC_FILE>)
	 {
		chop;

		my ($key, $value) = split(/[\=]/);

		print TMP_DSC_FILE "$_\n";

		if ($key eq "run" && $value eq $gene_table)
		{
		  print TMP_DSC_FILE "description=$web_descriptions{$gene_table}\n";
		  print TMP_DSC_FILE "iteration=" . get_iteration_dsc . "\n";

		  $printed_line = 1;
		}
	 }
  }

  if ($printed_line == 0)
  {
	 print TMP_DSC_FILE "run=$gene_table\n";
	 print TMP_DSC_FILE "description=$web_descriptions{$gene_table}\n";
	 print TMP_DSC_FILE "iteration=" . get_iteration_dsc . "\n";
  }

  move_file("$dsc_file.$r", "$dsc_file");
}

#------------------------------------------------------------------------------------
# print_links_to_runs
#------------------------------------------------------------------------------------
sub print_links_to_runs
{
  print NEW_HTML "<tr><td>&nbsp;</td></tr>\n";

  print NEW_HTML "<tr class=\"oddLine\"><td colspan=2><font size=4>Project Runs</td></tr>\n";

  print NEW_HTML "<tr><td colspan=2><br>\n";

  print NEW_HTML "<ul>";

  my @all_runs;
  my $all_runs_counter = 0;
  open(DSC_FILE, "<$web_dir/$prefix.dsc");
  while(<DSC_FILE>)
  {
	 chop;

	 my ($key, $value) = split(/=/);

	 if ($key eq "run") { $all_runs[$all_runs_counter] = $value; $all_runs_counter++; }
  }

  @all_runs = sort @all_runs;
  for (my $i = 0; $i < @all_runs; $i++)
  {
	 print NEW_HTML "<li><font size=3>";
	 print_link("$all_runs[$i]", "index.html#$all_runs[$i]");
  }

  print NEW_HTML "</ul></td></tr>\n";
}

#------------------------------------------------------------------------------------
# print_motifs
#------------------------------------------------------------------------------------
sub print_motifs
{
  my $str = "";

  $str .= "<tr><td>&nbsp;</td></tr>\n";

  my %pssm_strs;

  my @pssms = get_file_names_for_dir("$dir/out/motifs/*_i$next_iteration.pssm");
  for (my $i = 0; $i < @pssms; $i++)
  {
	 my $new_file_name = $pssms[$i];
	 $new_file_name =~ s/hidden_//g;
	 $new_file_name =~ /(.*)[\.]pssm/;
	 my $motif_name = $1;
	 while ($motif_name =~ /[\/]/) { $motif_name =~ /[\/](.*)/; $motif_name = $1; }

	 $pssm_strs{$motif_name} = "<tr class=\"oddLine\"><td colspan=2><font size=4><A name=\"$motif_name\">$motif_name</td></tr>\n";

	 $pssm_strs{$motif_name} .= "<tr><td colspan=2><br><font size=3><a href=\"$motif_name.pssm\"<b>Parameter File</b></a></td></tr>\n";

	 my $NumGenes = get_attribute_in_file($pssms[$i], "NumGenes", 1);
	 $pssm_strs{$motif_name} .= "<tr><td colspan=2><br><font size=3><b>$NumGenes</b></td></tr>\n";

	 my $LogPValue = get_attribute_in_file($pssms[$i], "LogPValue", 1);
	 $LogPValue =~ /LogPValue[\s\t]+(.*)/;
	 my $PValue = exp($1);
	 my $formattedPValue = format_number($PValue, 2);
	 $pssm_strs{$motif_name} .= "<tr><td colspan=2><br><font size=3><b>$LogPValue (P = $formattedPValue)</b></td></tr>\n";

	 my $LogLikelihood = get_attribute_in_file($pssms[$i], "LogLikelihood", 1);
	 $pssm_strs{$motif_name} .= "<tr><td colspan=2><br><font size=3><b>$LogLikelihood</b></td></tr>\n";

	 copy_file($pssms[$i], "$motifs_dir/$motif_name.pssm");
  }

  my @pss = get_file_names_for_dir("$dir/out/motifs/*_i$next_iteration.pssm.ps");
  for (my $i = 0; $i < @pss; $i++)
  {
	 my $new_file_name = $pss[$i];
	 $new_file_name =~ s/hidden_//g;
	 $new_file_name =~ /(.*)[\.]pssm/;
	 my $motif_name = $1;
	 while ($motif_name =~ /[\/]/) { $motif_name =~ /[\/](.*)/; $motif_name = $1; }

	 $pssm_strs{$motif_name} .= "<tr><td colspan=2><br><font size=3><a href=\"$motif_name.pdf\"<b>Motif Logo</b></a></td></tr>\n";

	 $pssm_strs{$motif_name} .= "<tr><td>&nbsp;</td></tr>\n";

	 execute("ps2pdf $pss[$i] $motifs_dir/$motif_name.pdf", 1);
  }

  foreach my $key (keys %pssm_strs)
  {
	 $str .= $pssm_strs{$key};
  }

  return $str;
}

#------------------------------------------------------------------------------------
# generate_motif_html
#------------------------------------------------------------------------------------
sub generate_motif_html
{
  create_dir("$motifs_dir");

  copy_file("$ENV{HOME}/develop/perl/web/motif_template.html", "$motifs_dir/motifs_$next_iteration.html");

  open(HTML, "<$motifs_dir/motifs_$next_iteration.html");
  open(MOTIF_HTML, ">$motifs_dir/index.$r.html");

  while(<HTML>)
  {
	 chop;

	 if ($_ eq "<GeneXPress_motifs>")
	 {
		my $str = print_motifs;

		print MOTIF_HTML $str;
	 }
	 else
	 {
		my $str = $_;

		$str =~ s/YourProjectNameHere/$web_project_title/g;

 		print MOTIF_HTML "$str\n";
	 }
  }

  move_file("$motifs_dir/index.$r.html", "$motifs_dir/motifs_$next_iteration.html");
}

#------------------------------------------------------------------------------------
# update_html
#------------------------------------------------------------------------------------
sub generate_html
{
  copy_file("$ENV{HOME}/develop/perl/web/index_template.html", "$web_dir/index.html");
  copy_file("$ENV{HOME}/develop/perl/web/styles.css", "$web_dir/");
  copy_file("$ENV{HOME}/develop/perl/web/GeneXPress.gif", "$web_dir/");

  open(HTML, "<$web_dir/index.html");

  while(<HTML>)
  {
	 chop;

	 if ($_ eq "<GeneXPress_runs>")
	 {
		open(DSC_FILE, "<$web_dir/$prefix.dsc");
    	my $current_run = "";
		while(<DSC_FILE>)
		{
		  chop;

		  my ($key, $value) = split(/=/);

		  if ($key eq "run") { $current_run = $value; }
		  elsif ($key eq "iteration") { parse_iteration_dsc($current_run, $value); }
		  elsif ($key eq "description") { $web_descriptions{$current_run} = $value; }
		}

		print_links_to_runs;

		my @all_runs;
		my $all_runs_counter = 0;
		open(DSC_FILE, "<$web_dir/$prefix.dsc");
		while(<DSC_FILE>)
		{
		  chop;
		
		  my ($key, $value) = split(/=/);

		  if ($key eq "run") { $all_runs[$all_runs_counter] = $value; $all_runs_counter++; }
		}
		
		@all_runs = sort @all_runs;
		for (my $i = 0; $i < @all_runs; $i++) { print_run($all_runs[$i]); }
	 }
	 elsif (/YourProjectDescriptionHere/)
	 {
		if (file_exists("$web_project_description"))
		{
		  open(DSC_FILE, "$web_project_description");
		  while(<DSC_FILE>) { print NEW_HTML $_; }
		}
		else
		{
		  print NEW_HTML "$web_project_description";
		}
	 }
	 else
	 {
		my $str = $_;

		$str =~ s/YourProjectNameHere/$web_project_title/g;

 		print NEW_HTML "$str\n";
	 }
  }

  move_file("$web_dir/index.$r.html", "$web_dir/index.html");
}

#------------------------------------------------------------------------------------
# main
#------------------------------------------------------------------------------------
copy_files_to_web;

clean_dsc_file;

if ($has_motifs) { generate_motif_html; }

update_description;

generate_html;
