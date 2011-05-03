#! /usr/bin/perl

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

sub change_attribute_in_file
{
  my $from_file = $_[0];
  my $to_file = $_[1];
  my $org_attribute = $_[2];
  my $new_attribute = $_[3];
  my $verbose = $_[4];

  my $r = int(rand 1000000000);

  execute("sed 's/$org_attribute/$new_attribute/g' $from_file > tmp.$r; mv tmp.$r $to_file", $verbose);
}

1
