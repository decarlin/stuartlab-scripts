#!/usr/bin/perl

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my %args = load_args(\@ARGV);

my $space_columns = get_arg("space_columns", 0, \%args);

my $id = 0;
while(<STDIN>)
{
  chop;

  print $id . "\t";

  for (my $i = 0; $i < $space_columns; $i++)
  {
    print "\t";
  }

  print $_ . "\n";

  $id++;
}

exit(0);

__DATA__
syntax: add_ids.pl

  -space_columns <num>: adds num space columns between the id and the data

