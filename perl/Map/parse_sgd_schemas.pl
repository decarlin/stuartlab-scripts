#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $null = "__NULL__";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my %args = load_args(\@ARGV);

my $dataset = "";
my $inside_description = 0;

while(<STDIN>)
{
  chop;

  if (/TABLE[\s]<b>([^<]+)<\/b>/)
  {
    $dataset = "\L$1";
    print "Parsing table $dataset\n";

    open(OUTFILE, ">$dataset.schema");
  }
  elsif ($dataset ne "")
  {
    if (/Other[\s]notes/ or /For[\s]the[\s]initial/)
    {
      $dataset = "";
    }
    else
    {
      /^([^\t\s]+)[\t\s]+([^\t\s]+)/;

      if ($2 eq "Required\." or $2 eq "Optional\.")
      {
	/^([^\t\s]+)[\t\s]+(.*)/;

	print OUTFILE "$1\t$2";
	$inside_description = 1;
      }
      elsif ($inside_description == 1)
      {
	if (/\S/)
	{
	  print OUTFILE $_;
	}
	else
	{
	  $inside_description = 0;
	  print OUTFILE "\n";
	}
      }
    }
  }
}

exit(0);

__DATA__
syntax: parse_sgd_schemas.pl

