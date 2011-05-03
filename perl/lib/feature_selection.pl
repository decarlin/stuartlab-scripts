#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/file_to_hash.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

my $MUTUAL_INFORMATION = "mi";
my $DOT_PRODUCT = "dot";
my $CORRELATION_COEFFICIENT = "cor";

my $fs_null_value = "FS___NULL___FS";

#--------------------------------------------------------------------------------
# DEBUG
#--------------------------------------------------------------------------------
sub DEBUG
{
#  print $_[0];
}

#--------------------------------------------------------------------------------
# print_data_max
#--------------------------------------------------------------------------------
sub print_data_max ($\@$\@\@$)
{
  my ($data_counter, $data_id_to_key_str, $feature_counter, $features_id_to_key_str, $scores_str, $outfile) = @_;

  if ($outfile ne $fs_null_value) { open(DATA_MAX, ">$outfile.data.dat"); }

  DEBUG("print_data_max: DataCounter=$data_counter FeatureCounter=$feature_counter\n");

  my @data_id_to_key = @{$data_id_to_key_str};
  my @features_id_to_key = @{$features_id_to_key_str};
  my @scores = @{$scores_str};

  # MAX SCORES BY DATA
  print "Data Key\tMax Feature Num\tMax Feature Key\tMax Score\n";
  if ($outfile ne $fs_null_value) { print DATA_MAX "Data Key\tMax Feature Num\tMax Feature Key\tMax Score\n"; }

  for (my $i = 0; $i < $data_counter; $i++)
  {
	 my $max_score = -10000000000;
	 my $max_feature_key = "";
	 my $max_feature_num = "";
	 for (my $j = 0; $j < $feature_counter; $j++)
	 {
		if ($scores[$i][$j] > $max_score)
		{
		  $max_feature_num = $j;
		  $max_score = $scores[$i][$j];
		  $max_feature_key = $features_id_to_key[$j];
	   }
	 }

	 print "$data_id_to_key[$i]\t";
	 print "$max_feature_num\t";
	 print "$max_feature_key\t";
	 print "$max_score\t";
	 print "\n";

	 if ($outfile ne $fs_null_value)
	 {
		print DATA_MAX "$data_id_to_key[$i]\t";
		print DATA_MAX "$max_feature_num\t";
		print DATA_MAX "$max_feature_key\t";
		print DATA_MAX "$max_score\t";
		print DATA_MAX "\n";
	 }
  }

  print "\n";
}

#--------------------------------------------------------------------------------
# print_feature_max
#--------------------------------------------------------------------------------
sub print_feature_max ($\@$\@\@$)
{
  my ($data_counter, $data_id_to_key_str, $feature_counter, $features_id_to_key_str, $scores_str, $outfile) = @_;

  if ($outfile ne $fs_null_value) { open(FEATURE_MAX, ">$outfile.feature.dat"); }

  DEBUG("print_feature_max: DataCounter=$data_counter FeatureCounter=$feature_counter\n");

  my @data_id_to_key = @{$data_id_to_key_str};
  my @features_id_to_key = @{$features_id_to_key_str};
  my @scores = @{$scores_str};

  # MAX SCORES BY DATA
  print "Feature Key\tMax Data Num\tMax Data Key\tMax Score\n";
  if ($outfile ne $fs_null_value) { print FEATURE_MAX "Feature Key\tMax Data Num\tMax Data Key\tMax Score\n"; }

  for (my $i = 0; $i < $feature_counter; $i++)
  {
	 my $max_score = -10000000000;
	 my $max_data_key = "";
	 my $max_data_num = "";
	 for (my $j = 0; $j < $data_counter; $j++)
	 {
		if ($scores[$j][$i] > $max_score)
		{
		  $max_data_num = $j;
		  $max_score = $scores[$j][$i];
		  $max_data_key = $data_id_to_key[$j];
	   }
	 }

	 print "$features_id_to_key[$i]\t";
	 print "$max_data_num\t";
	 print "$max_data_key\t";
	 print "$max_score\t";
	 print "\n";

	 if ($outfile ne $fs_null_value)
	 {
		print FEATURE_MAX "$features_id_to_key[$i]\t";
		print FEATURE_MAX "$max_data_num\t";
		print FEATURE_MAX "$max_data_key\t";
		print FEATURE_MAX "$max_score\t";
		print FEATURE_MAX "\n";
	 }
  }

  print "\n";
}

#--------------------------------------------------------------------------------
# print_full_matrix
#--------------------------------------------------------------------------------
sub print_full_matrix ($\@$\@\@$)
{
  my ($data_counter, $data_id_to_key_str, $feature_counter, $feature_id_to_key_str, $scores_str, $outfile) = @_;

  if ($outfile ne $fs_null_value) { open(FULL_MATRIX, ">$outfile.full.dat"); }

  DEBUG("print_full_matrix: DataCounter=$data_counter FeatureCounter=$feature_counter\n");

  my @data_id_to_key = @{$data_id_to_key_str};
  my @features_id_to_key = @{$feature_id_to_key_str};
  my @scores = @{$scores_str};

  # MAX SCORES BY DATA
  for (my $i = 0; $i < $feature_counter; $i++)
  {
	 print "\t$features_id_to_key[$i]";
	 if ($outfile ne $fs_null_value) { print FULL_MATRIX "\t$features_id_to_key[$i]"; }
  }
  print "\n";
  if ($outfile ne $fs_null_value) { print FULL_MATRIX "\n" }

  for (my $i = 0; $i < $data_counter; $i++)
  {
	 print "$data_id_to_key[$i]\t";
	 if ($outfile ne $fs_null_value) { print FULL_MATRIX "$data_id_to_key[$i]\t"; }

	 for (my $j = 0; $j < $feature_counter; $j++)
	 {
		print "$scores[$i][$j]\t";
		if ($outfile ne $fs_null_value) { print FULL_MATRIX "$scores[$i][$j]\t"; }
	 }
	 print "\n";
	 if ($outfile ne $fs_null_value) { print FULL_MATRIX "\n"; }
  }
  print "\n";
}

#--------------------------------------------------------------------------------
# select_from_file
#--------------------------------------------------------------------------------
sub select_from_file
{
  my ($data_file,
      $feature_file,
      $data_key_column,
      $data_keys_file,
      $data_start_data_column,
      $data_start_data_row,
      $feature_key_column,
      $feature_keys_file,
      $feature_start_data_column,
      $feature_start_data_row,
      $feature_selection_op,
      $ignore_self_score,
      $outfile) = @_;

  DEBUG("Data file:    $data_file [ $data_key_column $data_keys_file $data_start_data_column $data_start_data_row ]\n");
  DEBUG("Feature file: $feature_file [ $feature_key_column $feature_keys_file $feature_start_data_column $feature_start_data_row ]\n");
  DEBUG("Op:           $feature_selection_op\n\n");

  my @features = load_file_to_memory($feature_file, 1);
  my $num_features = @features;

  my %feature_allowed_keys;
  if ($feature_keys_file ne $fs_null_value) { %feature_allowed_keys = file_to_hash($feature_keys_file, 0); }

  my %data_allowed_keys;
  if ($data_keys_file ne $fs_null_value) { %data_allowed_keys = file_to_hash($data_keys_file, 0); }

  open(DATA_FILE, "<$data_file") or die "Could not open data file $data_file\n";
  for (my $i = 0; $i < $data_start_data_row; $i++) { my $skip_row = <DATA_FILE>;  }
  my @feature_id_to_key;
  my @data_id_to_key;
  my $data_counter = 0;
  my $max_feature_counter = -10000000;
  my @scores;

  while(<DATA_FILE>)
  {
    chop;

    DEBUG("Handling Data Item: $_\n");

    my @data_vec = split(/\t/);

    if ($data_keys_file eq $fs_null_value || $data_allowed_keys{$data_vec[$data_key_column]} eq "1")
    {
      my @to_compute_data_vec;
      for (my $i = $data_start_data_column; $i < @data_vec; $i++) { $to_compute_data_vec[$i - $data_start_data_column] = $data_vec[$i]; }
      DEBUG("   Data Vec: @to_compute_data_vec\n");
      print "Processing $data_vec[$data_key_column]...\n";

      $data_id_to_key[$data_counter] = $data_vec[$data_key_column];

      my $feature_counter = 0;
      for (my $i = $feature_start_data_row; $i < $num_features; $i++)
      {
	if ($feature_keys_file eq $fs_null_value || $feature_allowed_keys{$features[$i][$feature_key_column]} eq "1")
	{
	  DEBUG("      Scoring against Feature: $features[$i][$feature_key_column]\n");

	  my @to_compute_feature_vec;
	  my $num_feature_data_columns = @{$features[$i]};
	  for (my $j = $feature_start_data_column; $j < $num_feature_data_columns; $j++) { $to_compute_feature_vec[$j - $feature_start_data_column] = $features[$i][$j]; }
	  DEBUG("         Feature Vec: @to_compute_feature_vec\n");

	  my $feature_score = compute_score(\@to_compute_data_vec, \@to_compute_feature_vec, $feature_selection_op);

	  DEBUG("         Score: $feature_score\n");

	  $scores[$data_counter][$feature_counter] = $feature_score;

	  if ($features[$i][$feature_key_column] eq $data_vec[$data_key_column] && $ignore_self_score) { $scores[$data_counter][$feature_counter] = 0; }

	  $feature_id_to_key[$feature_counter] = $features[$i][$feature_key_column];

	  $feature_counter++;
	}
	
	if ($feature_counter > $max_feature_counter) { $max_feature_counter = $feature_counter; }
      }

      $data_counter++;
    }
  }
  DEBUG("\n");

  print_data_max($data_counter, @data_id_to_key, $max_feature_counter, @feature_id_to_key, @scores, $outfile);
  print_feature_max($data_counter, @data_id_to_key, $max_feature_counter, @feature_id_to_key, @scores, $outfile);
  print_full_matrix($data_counter, @data_id_to_key, $max_feature_counter, @feature_id_to_key, @scores, $outfile);
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  select_from_file($ARGV[0],
		   $ARGV[1],
		   get_arg("dk", 0, \%args),
		   get_arg("df", $fs_null_value, \%args),
		   get_arg("dc", 0, \%args),
		   get_arg("dr", 0, \%args),
		   get_arg("fk", 0, \%args),
		   get_arg("ff", $fs_null_value, \%args),
		   get_arg("fc", 0, \%args),
		   get_arg("fr", 0, \%args),
		   get_arg("o", $MUTUAL_INFORMATION, \%args),
		   get_arg("i",  0, \%args),
		   get_arg("out", $fs_null_value, \%args));
}
else
{
  print "Usage: feature_selection.pl data_file feature_file\n\n";
  print "      -dk <N>:          the column number of the key in the data file (default is 0)\n";
  print "      -df <file name>:  work only on records in the data file contained in this file (default is no file -- use all keys)\n";
  print "      -dc <N>:          skip the first N columns in each row in the data file (default is 0 -- use all columns)\n";
  print "      -dr <N>:          skip the first N rows in the data file (default is 0 -- use all rows)\n\n";
  print "      -fk <N>:          the column number of the key in the feature file (default is 0)\n";
  print "      -ff <file name>:  work only on records in the feature file contained in this file (default is no file -- use all keys)\n";
  print "      -fc <N>:          skip the first N columns in each row in the feature file (default is 0 -- use all columns)\n";
  print "      -fr <N>:          skip the first N rows in the feature file (default is 0 -- use all rows)\n\n";
  print "      -o  <Op>:         the operation to use when computing the score between a data vector and a feature vector. Supported:\n";
  print "                            mi  - mutual information (DEFAULT) -- use for discrete vectors only\n";
  print "                            dot - dot product\n";
  print "                            cor - correlation coefficient\n\n";
  print "      -i:               Ignore the score between a data item with the same key as a feature --> Set score to 0 (default DO NOT IGNORE)\n\n";
  print "      -out <file_name>: Output will be printed to files with this prefix\n\n";
}

1
