#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $skip_num = get_arg("skip", 0, \%args);
my $files_str = get_arg("f", 0, \%args);
my $missing_values = get_arg("m", "", \%args);
my $output_file = get_arg("o", "", \%args);

if (length($output_file) > 0) { open(OUTFILE, ">$output_file"); }

my @files = split(/\,/, $files_str);
my @header_files;
my @master_files;
my $current_num_columns = 0;
my %id2row;
my $last_row_id = 0;
my $file_counter = 0;

foreach my $file (@files)
{
  $file =~ /([^\s]+)/;
  $file = $1;

  print STDERR "Joining $file...\n";

  my $max_columns = 0;

  open(FILE, "<$file");
  while(<FILE>)
  {
    chop;

    my @row = split(/\t/);

    if (@row > $max_columns) { $max_columns = @row; }
  }

  open(FILE, "<$file");

  for (my $i = 0; $i < $skip_num; $i++)
  {
    my $line = <FILE>;
    chop $line;

    my @row = split(/\t/, $line);

    if ($file_counter == 0)
    {
      for (my $j = 0; $j < $max_columns; $j++)
      {
	$header_files[$i][$current_num_columns + $j] = $row[$j];
      }
    }
    else
    {
      for (my $j = 1; $j < $max_columns; $j++)
      {
	$header_files[$i][$current_num_columns + $j - 1] = $row[$j];
      }
    }
  }

  while(<FILE>)
  {
    chop;

    my @row = split(/\t/);

    my $row_id = $id2row{$row[0]};

    if (length($row_id) == 0)
    {
      $row_id = $last_row_id;
      $id2row{$row[0]} = $last_row_id;
      $last_row_id++;
      $master_files[$row_id][0] = $row[0];
    }

    if ($file_counter == 0)
    {
      for (my $j = 0; $j < $max_columns; $j++)
      {
	$master_files[$row_id][$current_num_columns + $j] = $row[$j];
      }
    }
    else
    {
      for (my $j = 1; $j < $max_columns; $j++)
      {
	$master_files[$row_id][$current_num_columns + $j - 1] = $row[$j];
      }
    }
  }

  $current_num_columns += $max_columns;
  if ($file_counter > 0) { $current_num_columns--; }

  $file_counter++;
}

if (length($output_file) == 0)
{
  for (my $i = 0; $i < $skip_num; $i++)
  {
    for (my $j = 0; $j < $current_num_columns; $j++)
    {
      print "$header_files[$i][$j]";
      if ($j < $current_num_columns - 1) { print "\t"; }
    }
    print "\n";
  }

  for (my $i = 0; $i < $last_row_id; $i++)
  {
    for (my $j = 0; $j < $current_num_columns; $j++)
    {
      if (length($master_files[$i][$j]) > 0) { print "$master_files[$i][$j]"; }
      else { print "$missing_values"; }

      if ($j < $current_num_columns - 1) { print "\t"; }
    }
    print "\n";
  }
}
else
{
  for (my $i = 0; $i < $skip_num; $i++)
  {
    for (my $j = 0; $j < $current_num_columns; $j++)
    {
      print OUTFILE "$header_files[$i][$j]";

      if ($j < $current_num_columns - 1) { print OUTFILE "\t"; }
    }
    print OUTFILE "\n";
  }

  for (my $i = 0; $i < $last_row_id; $i++)
  {
    for (my $j = 0; $j < $current_num_columns; $j++)
    {
      if (length($master_files[$i][$j]) > 0) { print OUTFILE "$master_files[$i][$j]"; }
      else { print OUTFILE "$missing_values"; }

      if ($j < $current_num_columns - 1) { print OUTFILE "\t"; }
    }
    print OUTFILE "\n";
  }
  close(OUTFILE);
}

print STDERR "Done. (kill me if system halts)\n";

__DATA__

combine_files.pl

   Combine files into one file using the keys of the rows to match up rows

   -f <f1,f2>:    List of all files, separated by commas

   -o <file>:     Output file name (default: standard output)

   -m:            Print this in case of missing values (default: "")

   -skip <num>:   Number of lines to skip and match up in all files

