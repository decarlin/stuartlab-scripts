#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $r = int(rand(100000));

if ($ARGV[0] eq '--help')
{
  print STDOUT <DATA>;
  exit(0);
}

my %args = load_args(\@ARGV);

my $gx_file = $ARGV[0];
my $data_file = $ARGV[1];

my $insert_column = get_arg("c", -1, \%args);
my $start_column = get_arg("sc", 0, \%args);
my $end_column = get_arg("ec", -1, \%args);
my $num_added_columns = $end_column - $start_column + 1;

#print "gx_file=$gx_file data_file=$data_file start column=$start_column  end_column=$end_column\n";

#---------------------------------------------------
# load the raw data and index it by the first column
#---------------------------------------------------
my @data;
my $num_genes = 0;
my %gene2id;
open(DATA_FILE, "<$data_file");
while(<DATA_FILE>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++) { $data[$num_genes][$i] = $row[$i]; }

  $gene2id{$row[0]} = $num_genes++;
}

#---------------------------------------------------
#
#---------------------------------------------------
#open(NOT_FOUND, ">tmp");
my $in_raw_data = 0;
my $in_experiments = 0;
my $last_experiment_id = 0;
my $new_experiment_id = 0;
my $num_experiment_attributes = 0;
my $num_experiments = 0;
open(GX_FILE, "<$gx_file");
while(<GX_FILE>)
{
  chop;

  if (/<TSCRawData/) { $in_raw_data = 1; print "$_\n"; }
  elsif (/<\/TSCRawData/) { $in_raw_data = 0; print "$_\n"; }
  elsif ($in_raw_data == 1)
  {
    my @row = split(/\t/);

    if ($num_experiments == 0) { $num_experiments = @row; }

    if ($insert_column == -1) { print "$_"; }
    else
    {
      for (my $i = 0; $i < $insert_column + 3; $i++) { print "$row[$i]\t"; }
    }

    my $gene_id = $gene2id{$row[0]};
    if ($row[0] eq "UID" and length($gene_id) == 0) { $gene_id = $data[0][0]; }

    #if (length($gene_id) == 0) { print NOT_FOUND "$row[0]\n"; }

    for (my $i = $start_column; $i <= $end_column; $i++)
    {
      if (length($gene_id) > 0) { print "$data[$gene_id][$i]\t"; }
      else { print "\t"; }
    }

    if ($insert_column != -1)
    {
      for (my $i = $insert_column + 3; $i < $num_experiments; $i++) { print "$row[$i]\t"; }
    }

    print "\n";
  }
  elsif (/Experiment[\s]Id=\"([^\"]+)\"/)
  {
    $last_experiment_id = $1;
    $new_experiment_id = $1;

    my $print_row_1 = "$_\n";

    my $attributes_line = <GX_FILE>;

    $attributes_line =~ /Value=\"([^\"]+)\"/;
    my $attributes_values = $1;
    my @attributes_value_split = split(/\;/, $attributes_values);
    $num_experiment_attributes = @attributes_value_split;

    if ($insert_column == $last_experiment_id)
    {
      &print_experiment_section($insert_column, $num_experiment_attributes);
    }

    my $id = $last_experiment_id + $num_added_columns;
    $print_row_1 =~ s/Experiment[\s]Id=\"([^\"]+)\"/Experiment Id=\"$id\"/g;
    print $print_row_1;
    print $attributes_line;
  }
  elsif (/<Objects[\s]Type=\"Experiments\"/) { $in_experiments = 1; print "$_\n"; }
  elsif ($in_experiments == 1 and /<\/Objects>/)
  {
    if ($insert_column == -1)
    {
      $new_experiment_id++;

      &print_experiment_section($new_experiment_id, $num_experiment_attributes);
    }

    print "$_\n";

    $in_experiments = 0;
  }
  else { print "$_\n"; }
}

sub print_experiment_section
{
  my ($start_experiment_id, $num_experiment_attributes) = @_;

  for (my $i = $start_column; $i <= $end_column; $i++)
  {
    print "<Experiment Id=\"$start_experiment_id\" name=\"$data[0][$i]\">\n";
    print "<Attributes AttributesGroupId=\"1\" Type=\"Full\" Value=\"";

    for (my $j = 0; $j < $num_experiment_attributes; $j++)
    {
      if ($j > 0) { print ";"; }

      print "0";
    }
    print "\">\n";

    print "</Attributes>\n";
    print "</Experiment>\n";

    $start_experiment_id++;
  }
}

#print "start_tsc_raw_data=$start_tsc_raw_data end_tsc_raw_data=$end_tsc_raw_data\n";

__DATA__

add_experiments_to_gx.pl gx_file data_file

   -c  <num>: the start column at which to insert the new experiments
   -sc <num>: start column in the data file for adding experiments
   -ec <num>: end column in the data file for adding experiments

