#!/usr/bin/perl

use strict;

my @organisms;
my @all_organisms = ('worm', 'yeast');
my $verbose       = 1;
my $dir           = undef;
my $test          = 0;
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
   elsif($arg eq '-test')
   {
      $test = 1;
   }
   elsif(-d $arg)
   {
      $dir = $arg;
   }
   else
   {
      push(@organisms, $arg);
   }
}

# If no organisms were supplied default to all organisms.
if($#organisms == -1)
{
  @organisms = @all_organisms;
}

if(not(defined($dir)))
{
   $dir = $test ? "$ENV{HOME}/public_html/cgi-bin/cassettes_test" :
                  "$ENV{MYPERLDIR}/lib/cassettes";
}

my $tmp_dir   = "$dir/tmp";
my $command   = "cd $tmp_dir; ";
my $exe       = $test ? "$ENV{HOME}/release/Cassettes/server_test_cassettes.exe" :
                        "$ENV{MYPERLDIR}/lib/server_cassettes.exe";

foreach my $organism (@organisms)
{
   my $data = "../data/$organism.tab";
   my $info = "$organism.server.jobs";
   my $lock = "$organism.server.lock";

   (-f "$tmp_dir/$data") or die("The data file '$tmp_dir/$data' for organism '$organism' does not exist");

   $command .= "$exe $data $info $lock";

   if($#organisms > 0)
   {
      $command .= ' & ';
   }
}

# Start up the processes.
$verbose and print STDERR "Starting the cassettes server with the command:\n\t'$command'\n";
system($command);
$verbose and print STDERR "Done starting the cassettes server.\n";

exit(0);

__DATA__
syntax: server_cassettes.pl [OPTIONS] [DIR] [ORGANISM1 ORGANISM2 ...]

DIR - The cgi-bin directory for cassettes.  Default is
         ~/public_html/cgi-bin/cassettes.

ORGANISMi - a valid organism name {worm, yeast}.  If not supplied a server for each will be
            started.

OPTIONS are:

-q: Quiet mode (default is verbose).

-test: Start a test cassettes server.  This makes the cgi-bin directory:
         ~/public_html/cgi-bin/cassettes_test if none is specified.
