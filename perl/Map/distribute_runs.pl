#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $command = get_arg("c", 0, \%args);
my $processes = get_arg("p", 1, \%args);
my $print_runs = get_arg("print", 0, \%args);
my $start_directory = get_arg("s", "", \%args);
my $end_directory = get_arg("e", "", \%args);

print "$command\n";

my @commands;
my $commands_counter = 0;

my @dirs = GetAllDirs(".");

if (length($start_directory) > 0)
{
  my @new_dirs;
  my $found_start = 0;
  foreach my $dir (@dirs)
  {
    if ($dir eq $start_directory) { $found_start = 1; }
    if ($found_start == 1) { push(@new_dirs, $dir); }
  }
  @dirs = @new_dirs;
}

if (length($end_directory) > 0)
{
  my @new_dirs;
  my $found_end = 0;
  foreach my $dir (@dirs)
  {
    if ($found_end == 0) { push(@new_dirs, $dir); }
    if ($dir eq $end_directory) { $found_end = 1; }
  }
  @dirs = @new_dirs;
}

if ($print_runs == 1)
{
  print "Directories\n===========\n";
  foreach my $dir (@dirs) { print "$dir\n"; }
}
else
{
  foreach my $dir (@dirs)
  {
    print "Adding directory $dir to $commands_counter\n";

    $commands[$commands_counter++] .= "cd $dir ; $command ; cd .. ; ";

    if ($commands_counter == $processes) { $commands_counter = 0; }
  }

  foreach my $c (@commands)
  {
    my $f = fork;
    if ($f == 0)
    {
      print "Executing $c\n\n";
      exec("$c");
    }
  }
}

__DATA__

distribute_runs.pl

   Goes into each of the directories at the current level and executes
   the command specified in each directory.
   if more than one processes is specified, then it executes the commands
   in parallel, distributing them evenly in terms of the number of directories.
   e.g. distribute_runs.pl -p 4 -c "make >& /dev/null &" will run the make
   on each directory and distribute the task across 4 processors

   -p <num>:         Number of processors to execute simultaneously
   -c <command>:     The command that gets distributed to each directory

   -print:           Just print the directories in order and do not run

   -s:               Name of the start directory (directories before this are ignored)
   -e:               Name of the end directory (directories after this are ignored)

