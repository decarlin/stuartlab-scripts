#! /usr/bin/perl

#-------------------------------------------------------------------------------------------------------------------
# input: 
#    records_infile - the name of the records file
#    records_outfile - the name of the output files
#    records_labels_outfile - if this is non-empty then it will store the record numbers included
#    records_remaining_outfile - if this is non-empty then those records which are not selected will be printed here
#    records_remaining_labels_outfile - if this is non-empty then it will store the record numbers not included
#    num_random_records_to_select
#    allow_duplicates - if we allow duplicates then this could be a selection for bootstrap
# output:
#    select num_random_records_to_select from records_infile and prints them into records_outfile
#-------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
	chop;
   ($id, $value) = split(/=/, $_, 2);

	$settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
$records_infile = $settings{"records_infile"};
$records_outfile = $settings{"records_outfile"};
$records_labels_outfile = $settings{"records_labels_outfile"};
$records_remaining_outfile = $settings{"records_remaining_outfile"};
$records_remaining_labels_outfile = $settings{"records_remaining_labels_outfile"};
$num_random_records_to_select = $settings{"num_random_records_to_select"};
$allow_duplicates = $settings{"allow_duplicates"};

open(INFILE, "<$records_infile") or die "could not open $records_infile\n";
open(OUTFILE, ">$records_outfile");

$num_records = 0;
while(<INFILE>)
{
  $records[$num_records] = $_;
  $num_records++;
}

if (length($records_labels_outfile) > 0)
{
  open(LABELS_OUTFILE, ">$records_labels_outfile");
}

$num_selected_records = 0;
while ($num_selected_records < $num_random_records_to_select)
{ 
  $r = int rand $num_records; # 0 .. num_records

  if ($allow_duplicates == 1 || $selected_records{$r} ne "1")
  {
	$selected_records{$r} = "1";

	print OUTFILE $records[$r];

	if (length($records_labels_outfile) > 0)
	{
	  print LABELS_OUTFILE $r . "\n";
	}

	$num_selected_records++;
  }
}

if (length($records_remaining_outfile) > 0)
{
  open(TEST_OUTFILE, ">$records_remaining_outfile");

  for ($i = 0; $i < $num_records; $i++)
  {
	if ($selected_records{$i} ne "1")
	{
	  print TEST_OUTFILE $records[$i];
	}
  }
}

if (length($records_remaining_labels_outfile) > 0)
{
  open(LABELS_OUTFILE, ">$records_remaining_labels_outfile");

  for ($i = 0; $i < $num_records; $i++)
  {
	if ($selected_records{$i} ne "1")
	{
	  print LABELS_OUTFILE $i . "\n";
	}
  }
}
