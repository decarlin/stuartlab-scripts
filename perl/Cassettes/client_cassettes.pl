#!/usr/bin/perl

use strict;

use Time::HiRes qw( sleep );
use Fcntl ':flock';

# How long (in seconds) we're willing to wait for stages of processing.
my $wait_client_lock      = 5;
my $wait_server_lock      = 5;
my $wait_result           = 120;

# How often to poll for each service (in seconds)
my $poll_client_lock      = 0.01;
my $poll_server_lock      = 1;
my $poll_result           = 0.10;

# my $tries_client_lock = 100;
# my $tries_server_lock = 10;
# my $tries_result      = 1200;
my $tries_client_lock = int($wait_client_lock / $poll_client_lock);
my $tries_server_lock = int($wait_server_lock / $poll_server_lock);
my $tries_result      = int($wait_result / $poll_result);

my $organism    = undef;
my $dir         = undef;
my $verbose     = 0;

my $file        = undef;

while(@ARGV)
{
   my $arg = shift @ARGV;

   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-v')
   {
      $verbose = 1;
   }
   elsif(-f $arg)
   {
      $file = $arg;
   }
   elsif(not(defined($organism)))
   {
      $organism = $arg;
      $organism =~ tr/A-Z/a-z/;
   }
   elsif(not(defined($dir)))
   {
      $dir = $arg;
   }
   else
   {
      &printError("Invalid argument '$arg'");
      exit(0);
   }
}

if(not(defined($file)))
{
   &printError("No genes file supplied");
   exit(0);
}

if(not(defined($organism)))
{
   &printError("No organism supplied");
   exit(0);
}

if(not(defined($dir)))
{
   &printError("No directory supplied");
   exit(0);
}

# Client lock file
my $client_lock_file = $dir . '/' . $organism . '.client.lock';
my $jobs_file        = $dir . '/' . $organism . '.server.jobs';

if(not(open(CLIENT_LOCK_FILE,">$client_lock_file")))
{
   &printError("Could not open $organism client lock file '$client_lock_file'");
   exit(0);
}

# Try to get a lock on the client lock file.
$verbose and print STDERR "Trying to get $organism client lock (file = '$client_lock_file')...";
for(my $i = 1; not(flock(CLIENT_LOCK_FILE,LOCK_EX)); $i++)
{
   $verbose and print STDERR " $i";

   if($i > $tries_client_lock)
   {
      $verbose and print STDERR " giving up.";
      &printError("Exceeded maximum wait time for $organism client lock ($wait_client_lock seconds)");
      exit(0);
   }
   sleep($poll_client_lock);
}
$verbose and print STDERR " got client lock.\n";

# Now that we've got the client lock, we need to get a lock on the
# file we need to communicate information to the server with.  We're
# now competing only with the server.  The server understands that
# if we create a file with the name $organism.lock that another
# process (us) have a lock on the information file.  The information
# file is $organism.info.  So, we need to wait until $organism.lock
# does *not* exist, create it and then write our information.

my $lock_file = $dir . '/' . $organism . '.server.lock';
$verbose and print STDERR "Trying to get $organism server lock (file = '$lock_file')...";
my $got_lock = 0;
for(my $i = 1; not($got_lock); $i++)
{
   $verbose and print STDERR " $i";

   if($i > $tries_server_lock)
   {
      $verbose and print STDERR " giving up.";
      &printError("Exceeded maximum wait time for $organism server lock ($wait_server_lock seconds)");
      exit(0);
   }
   elsif(not(-f $lock_file) and open(LOCK, ">$lock_file"))
   {
      $got_lock = 1;
   }
   else
   {
      sleep($poll_server_lock);
   }
}
$verbose and print STDERR " got server lock.\n";

# Now we tell the server where the gene list is by writing the
# filename into the information file.
if(not(open(INFO, ">>$jobs_file")) and not(open(INFO, ">$jobs_file")))
{
    &printError("Could not append to the $organism query jobs file '$jobs_file'");
    exit(0);
}
my $file_suffix = &getPathSuffix($file);
$verbose and print STDERR "Placing filename '$file_suffix' in the $organism jobs file...";
print INFO "$file_suffix\n";
close(INFO);
$verbose and print STDERR " done.\n";

# Release the server lock (by physically removing the file).
$verbose and print STDERR "Releasing $organism server lock file...";
close(LOCK);
`rm -f $lock_file`;
$verbose and print STDERR " released $organism server lock.\n";

# Release the lock on the client file.
$verbose and print STDERR "Releasing $organism client lock...";
flock(CLIENT_LOCK_FILE,LOCK_UN);
close(CLIENT_LOCK_FILE);
$verbose and print STDERR " released $organism client lock.\n";

# Now wait for a result file with the name $file.out to be created by
# the server.  When it is, print the result to standard output.
my $output_file = $file . '.out';
$verbose and print STDERR "Waiting for a result file '$output_file' to be created...";
for(my $i = 0; not(-f $output_file); $i++)
{
   $verbose and print STDERR " $i";

   if($i > $tries_result)
   {
      $verbose and print STDERR " giving up.";
      &printError("Exceeded maximum wait time for $organism result ($wait_result seconds)");
      exit(0);
   }
   # sleep(0.10);
   sleep($poll_result);
}

$verbose and print STDERR " found result file, printing it...";
my $result = `cat $output_file`;
print STDOUT $result;
$verbose and print STDERR " done printing.\n";

exit(0);

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub printError # ($message)
{
   my ($message) = @_;
   print STDOUT "ERROR:\t$message\n";
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getPathPrefix
{
   my $path = shift @_;

   $path =~ s/[^\/]*[\/]*$//;
   return $path;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getPathSuffix
{
  my $path = shift @_;

  while($path =~ /\/$/)
  {
    chop($path);
  }
  if($path =~ /([^\/]+)$/)
  {
    $path = $1;
  }
  return $path;
}

__DATA__
syntax: client_cassettes.pl [OPTIONS] GENES ORGANISM DIR

GENES: A file with a gene list inside.

ORGANISM: An organism name.  Allowed are:

              yeast
              worm

DIR: A directory where locks and files can be created/transferred.  This directory is
     used to communicate information to the server.

GENES: A file containing a list of gene names.  Can be passed in as either a parameter or through
       standard input.

OPTIONS are:

-v: Verbose mode.

