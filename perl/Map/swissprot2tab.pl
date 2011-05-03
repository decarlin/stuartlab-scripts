#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libmap_ncbi.pl";

my $fin = \*STDIN;
my $delim = "\t";
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(-f $arg)
  {
    open($fin,$arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

my ($alias_col,$alias_len,$acc_col,$acc_len,$name_col,$name_len) =
  &parseSwissprotHeader($fin);

# print "alias_col = '$alias_col'\n",
#       "alias_len = '$alias_len'\n",
#       "acc_col   = '$acc_col'\n",
#       "acc_len   = '$acc_len'\n",
#       "name_col  = '$name_col'\n",
#       "name_len  = '$name_len'\n";

my $col = $alias_col + $alias_len - 1;
my $max_col = $col;
$col = $acc_col + $acc_len - 1;
if($max_col < $col) { $max_col = $col; }
$col = $name_col + $name_len - 1;
if($max_col < $col) { $max_col = $col; }

while(<$fin>)
{
  my $len = length($_)-1;
  if(/\S/ and $len>$max_col)
  {
    chomp;

    my $alias_section = &clean(substr($_,$alias_col,$alias_len));
    my $accession   = &clean(substr($_,$acc_col,$acc_len));
    my $name  = &clean(substr($_,$name_col,$name_len));

    my @aliases;
    my $done_retrieving_aliases = 0;
    while(not($done_retrieving_aliases))
    {
      my @tmp_aliases = split(';', $alias_section);
      foreach my $alias (@tmp_aliases)
      {
	$alias = &clean($alias);
	if(length($alias)>0)
	{
	  push(@aliases,$alias);
	}
      }

      # If the last alias ends in a ';' there are more aliases on the next line.
      if($alias_section =~ /;\s*$/)
      {
	$_ = <$fin>;
	($_ eq eof) and die("Expected aliases on next line and found EOF.");

    	$alias_section = &clean(substr($_,$alias_col,$alias_len));
      }
      else
      {
        $done_retrieving_aliases = 1;
      }
    }

    $accession = &hasSwissprotAccession($accession);
    $name = &hasSwissprotName($name);
    # Print out only if they're valid Swissprot accessions and names
    if(length($accession)>0 and length($name)>0)
    {
      print "$name\t$accession\t", join(" ",@aliases), "\n";
    }
  }
}

exit(0);

sub clean
{
  my $section = shift;

  $section =~ s/^\s+//;       # remove leading spaces
  $section =~ s/\s+$//;       # remove trailing spaces
  $section =~ s/(\s)\s+/\1/g; # replace consecutive spaces with the first

  return $section;
}

__DATA__
syntax: swissprot2tab.pl [OPTIONS] < SWISSPROT

Outputs a tab-delimited file with the SwissProt entries (without the headers and
footers)

OPTIONS are:

