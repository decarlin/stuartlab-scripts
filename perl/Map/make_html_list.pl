#!/usr/bin/perl

use strict;

my @files;
my $html=0;
my $body=0;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }

  elsif($arg eq '-html')
  {
    $html = 1;
  }

  elsif($arg eq '-body')
  {
    $body = 1;
  }

  else
  {
    push(@files,$arg);
  }
}

if($#files>=0)
{
  $html and print "<html>\n";
  $body and print "<body>\n";

  print "<ul>\n";
  foreach my $file (@files)
  {
    print "  <li><a href=\"$file\">$file</a></li>\n";
  }
  print "</ul>\n";

  $body and print "</body>\n";
  $html and print "</html>\n";
}

exit(0);

__DATA__
syntax: make_html_list.pl [OPTIONS] FILE1 [FILE2 ...]

Prints an index to standard output

OPTIONS are:

-html: Output <html> at the top and </html> at the bottom of the file
-body: Output <body> at the top and </body> at the bottom of the file


