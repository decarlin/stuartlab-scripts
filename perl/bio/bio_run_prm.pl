#! /usr/bin/perl

use strict;

#-----------------------------------------------------------------------------------------------------------

sub Usage
{
  print "Usage: bio_run_prm.pl settings_file\n";
  print "      -p:    prepare_default_settings\n";
  print "      -cc:   compute_correlations\n";
  print "      -g:    prepare_gene_expression_data_files\n";
  print "      -a:    add_attributes_to_table\n";
  print "      -f:    fix_gene_expression_tables\n";
  print "      -c:    create_prm_meta\n";
  print "      -c:    create_prm_dsc\n";
  print "      -o:    run_prm_observed\n";
  print "      -h:    run_prm_hidden\n";
  print "      -t:    run_prm_test_set\n";
  print "      -m:    make_tsc\n";
  print "      -x:    genexpress analysis\n";
  print "      -d:    dissect\n";
  print "      -cpc:  compute_post_correlations\n";
  print "      -cac:  compute_attribute_changes\n";
  print "      -w:    copy_to_web\n";
  print "      -i <iteration number>:  the iteration number to work on (default: 0)\n";
  print "      -e <iteration number>:  the last iteration number (default -- same as start iteration)\n";
  exit;
}

#-----------------------------------------------------------------------------------------------------------

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/time.pl";

create_dir("tmp");

if (length($ARGV[0]) == 0) { Usage; }

my %settings = load_settings($ARGV[0]);

my $new_settings_file = "tmp/$ARGV[0].full";
if (file_exists($settings{"master_settings"}))
{
  execute("cat " . $settings{"master_settings"} . " $ARGV[0] > $new_settings_file", 1);
  %settings = load_settings($new_settings_file);
}
else
{
  execute("cp $ARGV[0] $new_settings_file", 1);
}

my %args = load_args(\@ARGV);
my $use_command_line_args = length($ARGV[1]) > 0;

my $executable_dir = "$ENV{MYPERLDIR}/lib/SamplePrograms";

if (!$use_command_line_args) { create_dir("Log"); open(LOG_FILE, ">Log/$ARGV[0].log"); }

#-------------------------------------------------------------------------------------------------------
# calc_arg
#-------------------------------------------------------------------------------------------------------
sub calc_arg
{
  my $res;

  if ($use_command_line_args) { $res = get_arg($_[0], 0, \%args); }
  else { $res = $settings{"$_[1]"}; }

  if (!$use_command_line_args) { print LOG_FILE "$_[1]=$res\n"; }
  print "$_[1]=$res\n";

  return $res;
}

#-------------------------------------------------------------------------------------------------------
# log_conditonal_execute
#-------------------------------------------------------------------------------------------------------
sub log_conditional_execute
{
  my $exec_str = $_[0];
  my $condition = $_[1];

  if ($condition == 1 || $condition eq "1")
  {
    print $exec_str . "\n";
    if (!$use_command_line_args) { print LOG_FILE "\n$exec_str   --- " . get_time() . "\n"; }
    execute($exec_str);
  }
}

#-------------------------------------------------------------------------------------------------------
# CONTROL ARGS
#-------------------------------------------------------------------------------------------------------
my $start_iteration = calc_arg("i", "start_iteration");
my $end_iteration = calc_arg("e", "end_iteration");
if ($use_command_line_args && $end_iteration eq "0") { $end_iteration = $start_iteration; print "fixed_end_iteration=$end_iteration\n" }

my $prepare_default_settings = calc_arg("p", "prepare_default_settings");
my $compute_correlations = calc_arg("cc", "compute_correlations");
my $prepare_gene_expression_data_files = calc_arg("g", "prepare_gene_expression_data_files");
my $add_attributes_to_table = calc_arg("a", "add_attributes_to_table");
my $fix_gene_expression_tables = calc_arg("f", "fix_gene_expression_tables");
my $create_prm_meta = calc_arg("c", "create_prm_meta");
my $create_prm_dsc = calc_arg("c", "create_prm_dsc");
my $run_prm_observed = calc_arg("o", "run_prm_observed");
my $run_prm_hidden = calc_arg("h", "run_prm_hidden");
my $run_prm_test_set = calc_arg("t", "run_prm_test_set");
my $make_tsc = calc_arg("m", "make_tsc");
my $genexpress_analysis = calc_arg("x", "genexpress_analysis");
my $dissect = calc_arg("d", "dissect");
my $compute_post_correlations = calc_arg("cpc", "compute_post_correlations");
my $compute_attribute_changes = calc_arg("cac", "compute_attribute_changes");
my $copy_to_web = calc_arg("w", "copy_to_web");

#-------------------------------------------------------------------------------------------------------
# RUNNING
#-------------------------------------------------------------------------------------------------------
my $settings_file = "tmp/settings." . $settings{"gene_table"} . ".0";

my $dir = $settings{"dir"};

log_conditional_execute("bio_prepare_default_settings.pl $new_settings_file $settings_file", $prepare_default_settings);

log_conditional_execute("bio_compute_correlations.pl $settings_file", $compute_correlations);

log_conditional_execute("bio_prepare_gene_expression_data_files.pl $settings_file", $prepare_gene_expression_data_files);

log_conditional_execute("bio_add_attributes_to_table.pl $settings_file", $add_attributes_to_table);

log_conditional_execute("bio_fix_gene_expression_tables.pl $settings_file", $fix_gene_expression_tables);

create_dir("$dir");
create_dir("$dir/out");
create_dir("$dir/out/motifs");

log_conditional_execute("bio_create_prm_meta.pl $settings_file", $create_prm_meta);
log_conditional_execute("bio_create_prm_dsc.pl $settings_file", $create_prm_dsc);

for (my $iteration = $start_iteration; $iteration <= $end_iteration; $iteration++)
{
  log_conditional_execute("bio_run_prm_observed.pl $settings_file $iteration", $run_prm_observed);

  log_conditional_execute("bio_run_prm_hidden.pl $settings_file $iteration", $run_prm_hidden);

  log_conditional_execute("bio_make_tsc.pl $new_settings_file $iteration", $make_tsc);

  log_conditional_execute("run_prm_test_set.pl $new_settings_file $iteration", $run_prm_test_set);

  log_conditional_execute("bio_genexpress_analysis.pl $new_settings_file $iteration", $genexpress_analysis);

  log_conditional_execute("bio_dissect.pl $new_settings_file $iteration", $dissect);

  log_conditional_execute("bio_compute_post_correlations.pl $new_settings_file $iteration", $compute_post_correlations);

  log_conditional_execute("bio_compute_attribute_changes.pl $settings_file $iteration", $compute_attribute_changes);

  log_conditional_execute("bio_copy_to_web.pl $new_settings_file $iteration", $copy_to_web);
}

if (!$use_command_line_args) { print LOG_FILE "\nDONE   --- " . get_time() . "\n"; }

