#! /usr/bin/perl

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
sub load_settings
{
  my %settings;
  my $id;
  my $value;

  if (length($_[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $_[0]; }

  open(SETTINGS, "<$settings_file") or die "could not open $settings_file";
  while (<SETTINGS>)
  {
	chop;
	($id, $value) = split(/=/, $_, 2);
	
	$settings{$id} = $value;
  }

  return %settings;
}

1
