#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap_data.pl";

use strict;

my @files;
my $num_chroms = 0;
my $verbose = 1;

while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-n')
  {
    $num_chroms = int(shift @ARGV);
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

foreach my $file (@files)
{
  my $chrom  = &get_chromosome_name($file,$num_chroms);
  my $format = &get_bio_format($file);

  if(length($chrom)>0 and length($format)>0)
  {
    my $link = "$chrom.$format";

    if(-l $link)
    {
      `rm $link`;
    }

    $verbose and print STDERR "Symbolic link '$link' ---> '$file'";
    `ln -s $file $link`;
    $verbose and print STDERR " created.\n";
  }
}

__DATA__
syntax: make_chrom_links.pl EXT FILE1 [FILE2 ...]

Creates links called chr_01.EXT, chr_02

OPTIONS are:
-q: quiet mode (default is verbose)
-n NUM: specify the number of autosomes in the organism (useful for interpreting
        roman numerals in file names!)

