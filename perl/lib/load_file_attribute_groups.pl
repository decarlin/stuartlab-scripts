#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";

#-------------------------------------------
# load_file_attribute_groups
#-------------------------------------------
sub load_file_attribute_groups
{
  my $setting_file = $_[0];
  my %settings = load_settings($settings_file);

  my %file_attribute_groups;

  my $attribute_groups = $settings{"attribute_groups"};
  for (my $i = 1; $i <= $attribute_groups; $i++)
  {
	 my $file = $settings{"attribute_group_file_$i"};
	 if (length($file) > 0)
	 {
		my %file_attributes = load_settings($file);

		foreach my $key (keys %file_attributes)
		{	
		  my $new_key;
		  if ($key =~ /NAME_(.*)/)
		  {
			 $new_key = "attribute_group_${i}_$1";
		  }
		  else
		  {
			 $new_key = "attribute_group_${key}_$i";
		  }

		  $file_attribute_groups{$new_key} = $file_attributes{$key};
		  #print "file_attribute_groups{$new_key}=$file_attribute_groups{$new_key}\n";
		}
	 }
  }

  return %file_attribute_groups;
}

1
