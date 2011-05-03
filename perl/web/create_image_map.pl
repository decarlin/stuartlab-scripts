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
my $w = get_arg("w", 0, \%args);
my $h = get_arg("h", 0, \%args);

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

my $sum = 0;
my @links;
my @sizes;
open(LINKS, "<$links_file");
while(<LINKS>)
{
  chop;

  my @row = split(/\t/);

  push(@sizes, $row[0]);
  push(@links, $row[1]);

  $sum += $row[0];
}

print "<map NAME=\"areas_$r\">\n";

my $new_y = $y;
for (my $i = 0; $i < @links; $i++)
{
  my $start_x = $x;
  my $end_x = $x + $w;
  my $start_y = int($new_y);
  my $height = $sizes[$i] / $sum * $h;
  my $end_y = int($new_y + $height);
  print "  <area SHAPE=RECT COORDS=\"$start_x,$start_y,$end_x,$end_y\" HREF=\"$links[$i]\" ALT=\"$links[$i]\">\n";

  $new_y += $height;
}

print "</map>\n";

__DATA__

create_image_map.pl <links file>

   Takes as input an tab-delimited links file, with two columns. The first column
   is the size of this object and the second column is the link to make. The size
   is given relative to the other sizes. That is, if the total height of the map
   is 100 pixels and there are two links, one with size 1 and the other with size 3,
   then the number of pixels allocated will be 25 and 75, respectively.

   -x <num>:   The start x of the map (default 0)
   -y <num>:   The start y of the map (default 0)
   -w <num>:   The width of the map
   -h <num>:   The height of the map

   For use inside the <img> tag:
   -i <file>:  The name of the file of the image
   -iw <num>:  The width of the image (default nothing goes here)
   -ih <num>:  The height of the image (default nothing goes here)

