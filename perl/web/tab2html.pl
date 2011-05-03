#!/usr/bin/perl

##############################################################################
##############################################################################
##
## tab2html.pl
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
#require "$ENV{MYPERLDIR}/lib/libhtml.pl";
require "/projects/sysbio/lab_apps/perl/lib/libhtml.pl";

use strict;
use warnings;

use Getopt::Long;

sub printUsageAndQuit() {
    print STDOUT <DATA>;
    exit(0);
}

# Flush output to STDOUT immediately.
$| = 1;



my $rowColor = undef; # color the make the rows
my $rowColor2 = undef; # color to make cells in even-numbered rows (optional) (overrides the default rowColor for those rows)
my $headerColor = undef;


$Getopt::Long::passthrough = 1; # ignore arguments we don't recognize in GetOptions, and put them in @ARGV
GetOptions("help|man|?" => sub { printUsageAndQuit(); }
	   , "hhhh=i" => sub { }
	   , "headercolor=s" => \$headerColor
	   , "rowcolor=s" => \$rowColor
	   , "rowcolor2=s" => \$rowColor2
    ) or printUsageAndQuit();

my @flags   = (
                  [     '-q', 'scalar',       0,      1]
                , [     '-d', 'scalar',    "\t",  undef]
                , [    '-ne', 'scalar',       0,      1]
                , [    '-h', 'scalar',        1,  undef]
                , [   '-num', 'scalar',       0,      1]
                , [  '-html', 'scalar',       0,      1]
                , [  '-body', 'scalar',       0,      1]
                , [  '-link', 'scalar',       0,      1]
                , ['-border', 'scalar',       0,      1]
                , ['-bgcolor', 'scalar',  undef,  undef]
                , [ '--file', 'scalar',     '-',  undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

my $verbose = not($args{'-q'});
my $delim   = $args{'-d'};
my $print_enclosing_table_tags = not($args{'-ne'});
my $number_lines = $args{'-num'};
my $html    = $args{'-html'};
my $body    = $args{'-body'};
my $border  = $args{'-border'};
my $link    = $args{'-link'};
my $bgcolor = $args{'-bgcolor'};
my $file    = $args{'--file'};
my $headers = $args{'-h'};

my @header;
my $lineNum = 0;
open(FILE, $file) or die("Could not open file '$file' for reading");

$html and print STDOUT "<html>\n";
$body and print STDOUT "<body>\n";

my $bgcolor_string = ($bgcolor) ? " BGCOLOR=\"${bgcolor}\" " : '';

$print_enclosing_table_tags and print STDOUT qq{<table border="$border" ${bgcolor_string} cellpadding=3 cellspacing=1>\n};

while(<FILE>)
{
   $lineNum++;

   my @x = split($delim, $_);

   chomp($x[$#x]);
   
   if($lineNum <= $headers) {
      for (my $i = 0; $i < scalar(@x); $i++) {
         if (defined($header[$i])) {
            $header[$i] .= '\n' . $x[$i];
         } else {
            $header[$i]  = $x[$i];
         }
      }

      if ($lineNum == $headers) {
	 if ($number_lines) { unshift(@header, "#"); } # add a header for the line number column
	 map {$_ = "<B>$_</B>"} @header; # boldify the header line!!

	 my $headerColorString = '';
	 if (defined($headerColor) && $headerColor) {
	     $headerColorString = qq{BGCOLOR="$headerColor"};
	 } elsif (defined($rowColor) && $rowColor) {
	     $headerColorString = qq{BGCOLOR="$rowColor"};
	 }

	 my $row = &getFormattedHtmlTableRow(\@header, $headerColorString, qq{ALIGN="CENTER"});
         print STDOUT $row, "\n";
      }

   } else {
      if($link) {
         for(my $i = 0; $i < @x; $i++) {
            $x[$i] = &wrapUrl($x[$i]);
         }
      }
      if ($number_lines) { unshift(@x, ($lineNum - $headers)); } # add the line number to the beginning

      my $whichColorString = '';
      if (defined($rowColor) && $rowColor) {

	  if (defined($rowColor2) && $rowColor2 && ($lineNum % 2 == 0)) {
	      $whichColorString = qq{BGCOLOR="$rowColor2"};
	  } else {
	      $whichColorString = qq{BGCOLOR="$rowColor"};
	  }
      }

      my $row = &getFormattedHtmlTableRow(\@x, $whichColorString, undef);
      print STDOUT $row, "\n";
   }
}
close(FILE);

if ($print_enclosing_table_tags) { print STDOUT "</table>\n"; }

if ($html) { print STDOUT "</html>\n"; }
if ($body) { print STDOUT "</body>\n"; }

exit(0);

sub wrapUrl {
   my ($text, $link, $tag_prefix, $link_prefix) = @_;
   $link = defined($link) ? $link : $text;
   $tag_prefix = defined($tag_prefix) ? $tag_prefix : '<a href=';
   $link_prefix = defined($link_prefix) ? $link_prefix : '';
   my $url = undef;
   if(defined($text)) {
      $url =   $tag_prefix
             . '"'
             . $link_prefix
             . $link
             . '">'
             . $text
             . '</a>'
             ;
   }
   return $url;
}


__DATA__
syntax: tab2html.pl [OPTIONS] [FILE | < FILE]

Reads a tab-delimited file WITH A HEADER, and outputs an HTML table.
(Set -h 0 if your input file does not have a header line.)

Example:

  cat myfile.tab | tab2html.pl -h 0 > output.html

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-ne NO ENCLOSING

    Prevents the enclosing <table>...</table> tags from
    being printed. Useful if you want to format the table
    manually outside of this script.

-num NUMBER LINES: Numbers each row in the table, starting from 1.

-link: Wrap a link around each entry in the table.

-border INTEGER

    Sets the table border. -border 0 means "no border."

-body
    If specified, put <BODY>...</BODY> tags around the table.

-html

    If specified, put <HTML>...</HTML> tags around the table.

--help

    Display this help.

--headercolor=COLORNAME

--rowcolor=COLORNAME

    Sets the color of the background for all the cells.

--rowcolor2=COLORNAME

    Sets the color of the alternating rows, like an old
    green-white financial printout
