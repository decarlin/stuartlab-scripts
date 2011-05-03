#!/usr/bin/perl

sub get_gif_width
{
  my ($file) = @_;

  my $width = `gifinfo -f "\\w" $file`;

  return $width;
}

sub get_gif_height
{
  my ($file) = @_;

  #my $info = `gifinfo $file`;
  #$info =~ /Size[\:][\s]([0-9]+)x([0-9]+)/;

  my $height = `gifinfo -f "\\h" $file`;

  return $height;
}

1

