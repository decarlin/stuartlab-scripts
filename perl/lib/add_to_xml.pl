#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

my $atx_null_value = "ATX___NULL___ATX";

#--------------------------------------------------------------------------------
# get_line_keys
#--------------------------------------------------------------------------------
sub get_line_keys
{
  my @values = split(/\s/, $_[0]);
  my %res;

  for (my $i = 0; $i < @values; $i++)
  {
    my ($key, $value) = split(/\=/, $values[$i]);
    $value =~ s/[\>]//g;

    $res{$key} = $value;
  }

  return %res;
}

#--------------------------------------------------------------------------------
# select_from_file
#--------------------------------------------------------------------------------
sub add_to_xml
{
  my ($input_file, $add_on_file, $start_tag, $end_tag) = @_;

  #print "$input_file, $add_on_file, $tag\n";

  # ADVANCE TO START TAG ON INPUT FILE
  open(INPUT_FILE, "<$input_file") or die "Could not open add on file $input_file\n";
  my $done = 0;
  while(<INPUT_FILE>) { print $_; chop; if ($_ =~ /$start_tag/) { last; } }

  # ADVANCE TO START TAG ON ADD ON FILE
  open(ADD_ON_FILE, "<$add_on_file") or die "Could not open add on file $add_on_file\n";
  my $done = 0;
  while(<ADD_ON_FILE>) { chop; if ($_ =~ /$start_tag/) { last; } }

  # MERGE
  while(<INPUT_FILE>)
  {
    chop;

    if (!($_ =~ /$end_tag/))
    {
      my $add_on_line = <ADD_ON_FILE>;
      chop $add_on_line;

      if ($_ =~ /^[\s]*[\<][^\/\s]+(.*)/)
      {
	my %line_keys = get_line_keys($1);

	$add_on_line =~ /^[\s]*[\<][^\/\s]+(.*)/;
	my %add_on_keys_values = get_line_keys($1);

	my $add_str = "";

	foreach my $key (keys %add_on_keys_values)
	{
	  if (length($line_keys{$key}) == 0 && length($add_on_keys_values{$key}) > 0)
	  {
	    $add_str .= " $key=$add_on_keys_values{$key}";
	  }
	}

	my $incomplete_line = substr($_, 0, length($_) - 1);
	print "$incomplete_line$add_str>\n";

      }
      else { print "$_\n"; }
    }
    else { print "$_\n"; last; }
  }

  # WRITE THE REST OF THE INPUT FILE
  while(<INPUT_FILE>) { print $_; }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if ($ARGV[0] eq "ARGS_ATX")
{
  if (length($ARGV[1]) > 0)
  {
 	 my %args = load_args(\@ARGV);

	 add_to_xml($ARGV[1],
		    $ARGV[2],
		    get_arg("st", $atx_null_value, \%args),
		    get_arg("et", $atx_null_value, \%args));
  }
  else
  {
 	 print "Usage: add_to_xml.pl input_file add_on_file\n";
	 print "      -st <start_token>:   start adding from lines containing <start_token>\n";
	 print "      -et <end_token>:     stop adding when encountering lines containing <end_token>\n";
  }
}

1
