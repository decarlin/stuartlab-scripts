#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $links_file = $ARGV[0];
my %args = load_args(\@ARGV);

my $x = get_arg("x", 0, \%args);
my $y = get_arg("y", 0, \%args);

my $image_file = get_arg("i", "", \%args);
my $image_width = get_arg("iw", -1, \%args);
my $image_height = get_arg("ih", -1, \%args);

my $r = int(rand(10000));

print "<A HREF=\"$r.map\">";
print "<img ";
if (length($image_file) > 0){ print "src=\"$image_file\" "; }
if ($image_width != -1) { print "width=\"$image_width\" "; }
if ($image_height != -1) { print "height=\"$image_height\" "; }
print " ISMAP USEMAP=\"#areas_$r\" border=\"0\"></A>\n\n";

print "<map NAME=\"areas_$r\">\n";

my $sum = 0;
my @links;
my @sizes;
open(LINKS, "<$links_file");
while(<LINKS>)
{
  chop;

  my @row = split(/\t/);

  my $start_x = $x + $row[0];
  my $start_y = $y + $row[1];
  my $end_x = $x + $row[2];
  my $end_y = $y + $row[3];
  print "  <area SHAPE=RECT COORDS=\"$start_x,$start_y,$end_x,$end_y\" HREF=\"$row[4]\" ALT=\"$row[4]\">\n";
}

print "</map>\n";

__DATA__

create_image_map_from_file.pl <links file>

   Takes as input an tab-delimited links file, with 5 columns. Each row corresponds
   to one rectangle in the resulting image map. The first 4 columns specify the 
   start_x, start_y, end_x, end_y of the rectangle, and the 5th column is the link
   to put for the rectangle.

   -x <num>:   The start x of the map (default 0)
   -y <num>:   The start y of the map (default 0)

   For use inside the <img> tag:
   -i <file>:  The name of the file of the image
   -iw <num>:  The width of the image (default nothing goes here)
   -ih <num>:  The height of the image (default nothing goes here)

