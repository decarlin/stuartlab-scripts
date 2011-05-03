#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";

#--------------------------------------------------------------------------------
# print_matrix
#--------------------------------------------------------------------------------
sub print_matrix (\@$)
{
  my ($vec, $columns_per_row) = @_;
  my @print_this_vec = @$vec;

  for (my $i = 0; $i < @print_this_vec; $i++)
  {
    $columns_per_row = @{$print_this_vec[$i]};
    for (my $j = 0; $j < $columns_per_row; $j++)
    {
      print "$print_this_vec[$i][$j]\t";
    }
    print "\n";
  }
  print "\n";
}

#--------------------------------------------------------------------------------
# sort_vec
#--------------------------------------------------------------------------------
sub sort_vec (\@$$)
{
  my ($vec, $key_idx, $sort_type) = @_;

  my @sort_this_vec = @$vec;
  my $columns_per_row = @{$sort_this_vec[0]};

  #print_matrix(@sort_this_vec, $columns_per_row);

  my $add_sort_type;
  if ($sort_type eq "n") { $add_sort_type = " -n "; }
  elsif ($sort_type eq "rn") { $add_sort_type = " -rn "; }
  elsif ($sort_type eq "r") { $add_sort_type = "  "; }
  elsif ($sort_type eq "rr") { $add_sort_type = " -r "; }

  my $r = int(rand 1000000000);

  open(OUT_FILE, ">tmp_$r");
  for (my $i = 0; $i < @sort_this_vec; $i++)
  {
    my $num_columns = length($sort_this_vec[$i][$key_idx]) > 0 ? @{$sort_this_vec[$i]} : $columns_per_row;
    print OUT_FILE "$sort_this_vec[$i][$key_idx]\t";
    for (my $j = 0; $j < $num_columns; $j++)
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
  for (my $i = 0; $i < @tmp_result; $i++)
  {
    my $num_columns = length($tmp_result[$i][0]) > 0 ? @{$tmp_result[$i]} : $columns_per_row;

    $result[$i][$key_idx] = $tmp_result[$i][0];
    for (my $j = 1; $j < $num_columns; $j++)
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

  print_matrix(@result, $columns_per_row);

  return @result;
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  my @sort_this_vec = load_file_to_memory($ARGV[0]);

  sort_vec(@sort_this_vec,
	   get_arg("k", 0, \%args),
	   get_arg("s", "n", \%args));
}
else
{
  print "Usage: sort_vec.pl data_file\n\n";
  print "      -k <N>:          The column number by which to sort (default is 0)\n";
  print "      -s <Sort Type>:  The type of sorting to use. Supported:\n";
  print "                            n   - numerically (DEFAULT)\n";
  print "                            rn  - reverse numerically\n";
  print "                            r   - regulat\n";
  print "                            rr  - reverse regular\n\n";
}

1
