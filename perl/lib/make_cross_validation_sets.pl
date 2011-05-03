#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
sub create_cross_validation_sets
{
  my ($records_infile, $records_outfile_prefix, $num_cross_validation_groups) = @_;

  my @test_records;

  open(INFILE, "<$records_infile") or die "could not open $records_infile\n";

  my $num_records = get_num_lines_in_file($records_infile);
  my $max_records_per_cv_group = int($num_records / $num_cross_validation_groups) + 1;
  my @records_per_cv_group;

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    $test_records[$i] = "";
    $records_per_cv_group[$i] = 0;
  }

  while(<INFILE>)
  {
    my $done = 0;

    while(!$done)
    {
      my $r = int rand $num_cross_validation_groups; # 0 .. num_cross_validation_groups

      if ($records_per_cv_group[$r] < $max_records_per_cv_group)
      {
	$test_records[$r] .= $_;
	$records_per_cv_group[$r]++;
	$done = 1;
      }
    }
  }

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    open(test_handle, ">" . $records_outfile_prefix . "_test_" . ($i + 1));

    print test_handle $test_records[$i];
  }

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    open(train_handle, ">" . $records_outfile_prefix . "_train_" . ($i + 1));

    for (my $j = 0; $j < $num_cross_validation_groups; $j++)
    {
      if ($i != $j)
      {
	print train_handle $test_records[$j];
      }
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  create_cross_validation_sets($ARGV[0],
										 get_arg("o", $ARGV[0], \%args),
										 get_arg("g", 5, \%args));
}
else
{
  print "Usage: make_cross_validation_sets.pl input_file \n\n";
  print "      -o <output stub>: prefix of the output file (default is same as input file)\n";
  print "      -g <cv number>:   number of cross validation groups to make (default 5)\n\n";
}
