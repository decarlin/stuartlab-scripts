#! /usr/bin/perl

sub get_file_dsc
{
  my $file = $_[0];
  my $verbose = $_[1];

  open(FILE_DSC, "<$file");
  $line = <FILE_DSC>;

  chop $line;

  my @result = split(/\t/, $line);

  return @result;
}

1
