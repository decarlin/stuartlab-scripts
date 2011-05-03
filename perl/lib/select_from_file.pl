#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_load_file_to_memory.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

my $sff_null_value = "SFF___NULL___SFF";

#--------------------------------------------------------------------------------
# select_from_file
#--------------------------------------------------------------------------------
sub select_from_file
{
  my ($input_file,
      $selection_file,
      $input_key_column,
      $selection_key_column,
      $input_print_first_rows,
      $input_skip_rows,
      $diff_file,
      $do_not_print_inputs_found,
      $print_inputs_not_found,
      $print_features_not_found,
      $random_number,
      $start_token,
      $end_token) = @_;

  #print "$input_file, $selection_file, $input_key_column, $selection_key_column, $input_skip_rows, $diff_file, $random_number, $start_token, $end_token\n";

  my %allowed_keys;

  if ($selection_file ne $sff_null_value)
  {
    open(SELECTION_FILE, "<$selection_file") or die "select_from_file: could not open selection file $selection_file\n";

    while(<SELECTION_FILE>)
    {
      chop;

      my @record = split(/\t/);

      $allowed_keys{$record[$selection_key_column]} = "1";
    }
  }

  if ($random_number > 0)
  {
    my $num_records = get_num_lines_in_file($input_file) - $input_print_first_rows;

    open(INPUT_FILE, "<$input_file") or die "select_from_file: could not open input file $input_file\n";

    while(<INPUT_FILE>)
    {
      chop;

      my $ran = int(rand $num_records);

      my @record = split(/\t/);

      if ($ran <= $random_number)
      {
	$allowed_keys{$record[$input_key_column]} = "1";
      }
    }
  }

  my %allowed_keys_found;
  my $force_allowed_tokens = 0;
  my %input_keys_not_found;
  my $rows = 0;
  open(INPUT_FILE, "<$input_file") or die "select_from_file: could not open input file $input_file\n";
  while(<INPUT_FILE>)
  {
    chop;

    if ($rows < $input_print_first_rows || $rows < $input_skip_rows)
    {
      if ($rows < $input_print_first_rows) { print "$_\n"; }
      $rows++;

      if ($allowed_keys{$record[$input_key_column]} eq "1")	{ $allowed_keys_found{$record[$input_key_column]} = "1"; }
    }
    else
    {
      my @record = split(/\t/);

      if ($force_allowed_tokens == 0 && $_ =~ /^$start_token/ && $start_token ne $sff_null_value) { $force_allowed_tokens = 1; }
		
      if ($allowed_keys{$record[$input_key_column]} eq "1" || $force_allowed_tokens)
      {
	if (!$do_not_print_inputs_found) { print "$_\n"; }

	$allowed_keys_found{$record[$input_key_column]} = "1";
      }
      else
      {
	if ($print_inputs_not_found) { print "$_\n"; }
	$input_keys_not_found{$record[$input_key_column]} = "1";
      }

      if ($force_allowed_tokens == 1 && $_ =~ /^$end_token/ && $end_token ne $sff_null_value) { $force_allowed_tokens = 0; }
    }
  }

  if ($print_features_not_found) { foreach $key (keys %allowed_keys) { if ($allowed_keys_found{$key} ne "1") {  print "$key\n"; } } }

  if ($diff_file ne $sff_null_value && length($diff_file) > 0)
  {
    open(DIFF_FILE, ">$diff_file");
	
    print DIFF_FILE "Selected Keys Not Found:\n";
    foreach $key (keys %allowed_keys) { if ($allowed_keys_found{$key} ne "1") { print DIFF_FILE "$key\n"; } }

    print DIFF_FILE "\n\nInput Keys Not Found:\n";
    foreach $key (keys %input_keys_not_found) { print DIFF_FILE "$key\n"; }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if ($ARGV[0] eq "ARGS_SFF")
{
  if (length($ARGV[1]) > 0)
  {
    my %args = load_args(\@ARGV);

    select_from_file($ARGV[1],
		     get_arg("f",   $sff_null_value, \%args),
		     get_arg("i",   0, \%args),
		     get_arg("s",   0, \%args),
		     get_arg("k",   0, \%args),
		     get_arg("sk",  0, \%args),
		     get_arg("d",   $sff_null_value, \%args),
		     get_arg("pni", 0, \%args),
		     get_arg("pdi", 0, \%args),
		     get_arg("pds", 0, \%args),
		     get_arg("r",   0, \%args),
		     get_arg("st",  $sff_null_value, \%args),
		     get_arg("et",  $sff_null_value, \%args));
  }
  else
  {
    print "Usage: select_from_file.pl input_file\n";
    print "      -f <selection_file>: select using keys that reside in this file\n";
    print "      -i <column number>:  use this column number as the key in the input file (default is 1)\n";
    print "      -s <column number>:  use this column number as the key in the selection file (default is 1)\n";
    print "      -k <rows>:           prints the first k rows of the input file as is (no selection on them) (default is 0)\n";
    print "      -sk <rows>:          skips the first k rows of the input file as is (no selection on them) (default is 0)\n";
    print "      -d <diff file>:      prints the keys from the input file not found in the selection file and vice versa into a file called <diff file>\n";
    print "      -pni:                do NOT print the input keys found (DEFAULT is on)\n";
    print "      -pdi:                prints the input keys NOT found\n";
    print "      -pds:                prints the feature keys NOT found\n";
    print "      -r <num records>:    select num_records randomly from the file\n";
    print "      -st <start_token>:   select records only after seeing a line beginning with <start_token>\n";
    print "      -et <end_token>:     stop selection when encountering a line beginning with <end_token>\n";
  }
}

1
