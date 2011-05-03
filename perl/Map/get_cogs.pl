#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap_data.pl";

use strict;

my $alias_file = '';
my $cogs_file_name = '';
my $organism = '';
my $delim = "\t";
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-alias')
  {
    $alias_file = shift @ARGV;
  }
  elsif(length($cogs_file_name)==0)
  {
    $cogs_file_name = $arg;
  }
  elsif(length($organism)==0)
  {
    $organism = $arg;
  }
}

length($cogs_file_name)>0 or die("Please supply a COGs file.");
my $cogs_file;
open($cogs_file, $cogs_file_name) or die("Could not open '$cogs_file_name'.");

length($organism)>0 or die("Please supply a COGs file.");
my $cogs_id = &cogs_organism_id($organism);

my $cog = '';
my $opened_alias_file = 0;
while(<$cogs_file>)
{
  if(/(COG\d\d\d\d)/)
  {
    $cog = $1;
  }

  elsif(/^\s+$cogs_id:\s+(\S.+\S)\s*$/)
  {
    my @orfs = split(/\s+/,$1);
    foreach my $orf (@orfs)
    {
      $orf = &beautify_orf_name($orf,$organism);
      my $alias = $orf;
      $orf = &normalize_orf_name($orf,$organism);
      print $cog, $delim, $orf, "\n";

      if(length($alias_file)>0 and ($alias ne $orf))
      {
        if(not($opened_alias_file))
        {
          open(ALIAS,">$alias_file") or die("Could not open alias file '$alias_file' for writing.");
	  $opened_alias_file = 1;
        }
        print ALIAS "$alias\t$orf\n";

      }
    }
  }
}

exit(0);

__DATA__
syntax: get_cogs.pl COGS_FILE ORGANISM

-alias FILE: Tell the script to save aliases it finds to FILE.


