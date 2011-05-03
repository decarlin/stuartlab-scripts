#! /usr/bin/perl

use strict;

require "/u/erans/D/Biology/utils/lib/bio_execute.pl";
require "/u/erans/D/Biology/utils/lib/bio_load_file_to_memory.pl";

sub print_matrix (\@$)
{
  my ($vec, $columns_per_row) = @_;
  my @print_this_vec = @$vec;

  my $i;
  my $j;
  for ($i = 0; $i < @print_this_vec; $i++)
  {
	for ($j = 0; $j < $columns_per_row; $j++)
	{
	  print "$print_this_vec[$i][$j]\t";
	}
	print "\n";
  }
  print "\n";
}

sub sort_vec (\@$$$)
{
  my ($vec, $columns_per_row, $key_idx, $sort_type) = @_;

  my @sort_this_vec = @$vec;

  #print_matrix(@sort_this_vec, $columns_per_row);

  my $add_sort_type;
  if ($sort_type eq "numeric") { $add_sort_type = " -n "; }
  elsif ($sort_type eq "numeric_reverse") { $add_sort_type = " -rn "; }
  elsif ($sort_type eq "regular") { $add_sort_type = "  "; }
  elsif ($sort_type eq "regular_reverse") { $add_sort_type = " -r "; }

  my $r = int(rand 1000000000);

  open(OUT_FILE, ">tmp_$r");
  my $i;
  my $j;
  for ($i = 0; $i < @sort_this_vec; $i++)
  {
	print OUT_FILE "$sort_this_vec[$i][$key_idx]\t";
	for ($j = 0; $j < $columns_per_row; $j++)
	{
	  if ($j != $key_idx)
	  {
		print OUT_FILE "$sort_this_vec[$i][$j]\t";
	  }
	}	
	print OUT_FILE "\n";
  }

  execute("sort $add_sort_type tmp_$r > tmp2_$r");

  my @tmp_result = load_file_to_memory("tmp2_$r");

  my @result;
  for ($i = 0; $i < @tmp_result; $i++)
  {
	$result[$i][$key_idx] = $tmp_result[$i][0];
	for ($j = 1; $j < $columns_per_row; $j++)
	{
	  if ($j > $key_idx)
	  {
		$result[$i][$j] = $tmp_result[$i][$j];
	  }
	  else
	  {
		$result[$i][$j-1] = $tmp_result[$i][$j];
	  }
	}	
  }

  execute("rm tmp_$r");
  execute("rm tmp2_$r");

  #print_matrix(@result, $columns_per_row);

  return @result;
}

1

