#! /usr/bin/perl

sub file_to_hash
{
  my $file = $_[0];
  my $key_column = $_[1];

  open(FILE_DSC, "<$file") or die "could not open $file\n";
  #$line = <FILE_DSC>;

  my %result;

  while(<FILE_DSC>)
  {
    chop;
	
    my @data = split(/\t/, $_);

    $result{$data[$key_column]} = "1";
  }

  return %result;
}

1
