#!/usr/bin/perl

##############################################################################
##############################################################################
##
## color.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use GD;

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',             0,     1]
                , [    '-x', 'scalar',             1, undef]
                , [    '-y', 'scalar',             2, undef]
                , [    '-c', 'scalar',             3, undef]
                , [    '-d', 'scalar',          "\t", undef]
                , [    '-h', 'scalar',             1, undef]
                , [    '-s', 'scalar',         undef, undef]
                , [    '-p', 'scalar',         undef, undef]
                , [    '-b', 'scalar', '255,255,255', undef]
                , [ '-text', 'scalar',             0,     1]
                , ['-flipx', 'scalar',             0,     1]
                , ['-flipy', 'scalar',             0,     1]
                , ['--file', 'scalar',           '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});


my $x_col      = $args{'-x'} - 1;
my $y_col      = $args{'-y'} - 1;
my $color_col  = $args{'-c'} - 1;
my $delim      = $args{'-d'};
my $size       = $args{'-s'};
my $pixel_size = $args{'-p'};
my $headers    = $args{'-h'};
my $background = $args{'-b'};
my $flipx      = $args{'-flipx'};
my $flipy      = $args{'-flipy'};
my $text       = $args{'-text'};
my $file       = $args{'--file'};

# allocate some colors
# $white = $image->colorAllocate(255,255,255);
# $black = $image->colorAllocate(0,0,0);
# $red   = $image->colorAllocate(255,0,0);
# $blue  = $image->colorAllocate(0,0,255);

# make the background transparent and interlaced
# $image->interlaced('true');

# Put a black frame around the picture
# $image->rectangle(0,0,99,99,$black);

# Draw a blue oval
# $image->arc(50,50,95,75,0,360,$blue);

# And fill it with red
# $image->fill(50,50,$red);

my $line_no = 0;
my $filep = &openFile($file);
my ($min_x, $max_x, $min_y, $max_y) = (undef, undef, undef, undef);
my @data;
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers and /\S/)
   {
      chomp;

      my @tuple = split($delim);
      chomp($tuple[$#tuple]);

      my $x     = $tuple[$x_col];
      my $y     = $tuple[$y_col];
      my $color = $tuple[$color_col];
      my @options;

      $x = $flipx ? -$x : $x;

      $y = $flipy ? -$y : $y;

      $min_x = (not(defined($min_x)) or ($x < $min_x)) ? $x : $min_x;

      $max_x = (not(defined($max_x)) or ($x > $max_x)) ? $x : $max_x;

      $min_y = (not(defined($min_y)) or ($y < $min_y)) ? $y : $min_y;

      $max_y = (not(defined($max_y)) or ($y > $max_y)) ? $y : $max_y;

      $color = defined($color) ? $color : '0,0,0';

      my @row = ($x, $y, $color, @options);

      push(@data, \@row);
   }
}
close($filep);

if(not(defined($size)))
{
   my $w = int($max_x - $min_x);

   my $h = int($max_y - $min_y);

   $size = $w . 'x' . $h;
}

my ($height, $width) = split(/[Xx]/, $size);

my $total = $height * $width;

my ($pixel_height, $pixel_width) = defined($pixel_size) ? split(/[Xx]/, $pixel_size) : (undef, undef);

# create a new image
my $image = new GD::Image($height,$width);

my %allocated_colors;

$allocated_colors{'background'} = $image->colorAllocate(split(',',$background));

$allocated_colors{$background}  = $allocated_colors{'background'};

$image->transparent($allocated_colors{'background'});

my %raw;
foreach my $row (@data)
{
   my ($x, $y, $color_spec, @options) = @{$row};

   my $w = int(($x - $min_x) / ($max_x - $min_x) * ($width - 1)) + 1;

   my $h = int(($y - $min_y) / ($max_y - $min_y) * ($height - 1)) + 1;

   if(not(exists($allocated_colors{$color_spec})))
   {
      my ($r, $g, $b) = split(',',$color_spec);

      $allocated_colors{$color_spec} = $image->colorAllocate($r,$g,$b);
   }

   my $color = $allocated_colors{$color_spec};

   if(defined($pixel_size))
   {
      my $w1 = int($w - $pixel_width / 2);
      my $w2 = int($w + ($pixel_width - 1) / 2);
      my $h1 = int($h - $pixel_height / 2);
      my $h2 = int($h + ($pixel_height - 1) / 2);
      $image->rectangle($w1, $h1, $w2, $h2, $color);
      # $image->fill($w, $h, $color);
   }
   else
   {
      $image->setPixel($w, $h, $color);
   }

   if($text)
   {
      $raw{$w,$h} = $color_spec;
   }
}

if(not($text))
{
   # Convert the image to GIF and print it on standard output
   binmode STDOUT;
   print $image->gif;
}
else
{
   for(my $j = 1; $j < $height; $j++)
   {
      for(my $i = 1; $i < $width; $i++)
      {
         my $color = exists($raw{$i,$j}) ? $raw{$i,$j} : $background;

         print STDOUT "$i\t$j\t$color\n";
      }
   }
}

exit(0);


__DATA__
syntax: color.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-x COL: Column the x-coordinate can be fond in (default is 1).

-y COL: Column the y-coordinate can be fond in (default is 2).

-c COL: Column the color can be found in (default is 3).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-s HEIGHTxWIDTH Specifies the size of the resulting image (default is fits the image
                to the input data).

-b COLOR: Set the background color (default is 0,0,0 -- white).

-p HEIGHTxWIDTH: Set the size of a single pixel.

-flipx: Reflect about the x-direction.

-flipy: Reflect about the y-direction.



