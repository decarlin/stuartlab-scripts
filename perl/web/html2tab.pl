#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## html2tab.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     1, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-l', 'scalar',     0,     1]
                , [    '-f', 'scalar',     0,     1]
                , [    '-t', 'scalar',     1,     0]
                , [    '-r', 'scalar',     1,     0]
                , [    '-b', 'scalar',     0,     1]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $field         = (defined($args{'-k'}) ? $args{'-k'} : $args{'-f'}) - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $links         = $args{'-l'};
my $print_tab_num = $args{'-t'};
my $print_row_num = $args{'-r'};
my $format        = $args{'-f'};
my @format_chars  = split(" ", "a strong tt br b font sup pre");
my $blanks        = $args{'-b'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

open(FILE, $file) or die("Could not open file '$file' for reading");

my @file = <FILE>;

$file = join("\n", @file);

$file =~ s/<![^>]*>//gi;

$file =~ s/<\/html[^>]*>//gi;

$file =~ s/<\/body[^>]*>//gi;

@file = split(/\<table[^>]*>/i,$file);

$verbose and print STDERR scalar(@file)-1, " tables found.\n";

for(my $t = 1; $t < @file; $t++)
{
   $file[$t] =~ s/<\/table[^>]*>//gi;

   my @rows = split(/<tr[^>]*>/i, $file[$t]);

   my $r = 0;

   foreach my $row (@rows)
   {
      if($blanks or $row =~ /<td/i)
      {
         $row =~ s/<td[^>]*>/$delim/gi;
         $row =~ s/\n//g;
         $row =~ s/<\/td[^>]*>//gi;
         $row =~ s/<\/tr[^>]*>//gi;

         if(not($format))
         {
            foreach my $format_char (@format_chars)
            {
               $row =~ s/<$format_char[^>]*>/ /gi;
               $row =~ s/<\/$format_char[^>]*>//gi;
            }
         }

         if(not($links))
         {
            # Get rid of links
            $row =~ s/<a\s+href\s*=[^>]*>([^<]*)<\/a[^>]*>/$1/gi;

            # Get rid of labels
            $row =~ s/<a\s+Name\s*=[^>]*>//gi;

            # Get rid of html spaces.
            $row =~ s/&nbsp;//gi;
         }

         my @headers;

         if($print_tab_num)
         {
            push(@headers, $t);
         }

         $r++;

         if($print_row_num)
         {
            push(@headers, $r);
         }

         print join($delim, @headers), $row, "\n";
      }
   }
}

exit(0);


__DATA__
syntax: html2tab.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-l: Keep links in the table (default removes anything like http://)

-f: Keep formatting of HTML (default removes things like <br>).

-t: Suppress printing the table number (default prints an index for each table)

-r: Suppress printing the row number (default prints an index for each row).

-b: Print blank rows (default does not print these).

