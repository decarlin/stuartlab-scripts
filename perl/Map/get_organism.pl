#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap.pl";

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my $case = 'none';
my @files;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }

  elsif($arg eq '-')
  {
    while(<STDIN>)
    {
      if(/\S/)
      {
        chomp;
        push(@files,$_);
      }
    }
  }

  elsif($arg eq '-u')
  {
    $case = 'upper';
  }
  elsif($arg eq '-l')
  {
    $case = 'lower';
  }
  else
  {
    push(@files, $arg);
  }
}

$#files>=0 or die("Please supply a file.");

foreach my $file (@files)
{
  my $organism = &getMapOrganismFromPath($file);

  if($case eq 'upper')
  {
    $organism =~ tr/a-z/A-Z/;
  }
  elsif($case eq 'lower')
  {
    $organism =~ tr/A-Z/a-z/;
  }

  print STDOUT "$organism\n";
}

exit(0);

__DATA__
syntax: get_organism.pl PATH


Extracts the organism from the path PATH and prints it to standard output.

