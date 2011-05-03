#!/usr/bin/perl

use strict;

if($#ARGV != 0)
{
   print STDOUT <DATA>;
   exit(0);
}

my $n = int($ARGV[0]);

my @organism_commands = (
                           'server_cassettes.pl worm',
                           'server_cassettes.pl yeast'
			);

my $command = '';

for(my $i = 0; $i < $n; $i++)
{
   foreach my $organism_command (@organism_commands)
   {
      $command .= $organism_command . ' & ';
   }
}

system($command);

exit(0);

__DATA__
syntax: start_multi_servers_cassettes.pl N

N: The number of servers (for each organism) to start.

