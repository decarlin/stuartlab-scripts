#!/usr/bin/perl

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my $schema = $ARGV[0];
my $data = $ARGV[1];
my $sgd = $ARGV[2];

system("cut -f 1 $schema | transpose.pl > $sgd");
system("cat $data >> $sgd\n");

exit(0);

__DATA__
syntax: make_sgd_file.pl schema data sgd_file


