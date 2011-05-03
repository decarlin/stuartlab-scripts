#!/usr/bin/perl

use strict;

my $tmp_dir = '/tmp';
my $file = '';
my $backup = '';
my $url = '';
my $verbose = 1;
my $make_backup = 1;

my $fetch_program = 'wget';
my $fetch_command = '';
my $extra_args = '';

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
  elsif($arg eq '-nobackup')
  {
    $make_backup = 0;
  }
  elsif($arg eq '-lynx')
  {
    $fetch_program = 'lynx';
  }
  elsif($arg eq '-wget')
  {
    $fetch_program = 'wget';
  }
  elsif($arg eq '-tmp')
  {
    $tmp_dir = shift @ARGV;
  }
  elsif(length($file)==0)
  {
    $file = $arg;
  }
  elsif(length($url)==0)
  {
    $url = $arg;
  }
  else
  {
    $extra_args .= ' ' . $arg;
  }
}

if($fetch_program =~ /wget/i)
{
  $fetch_command = 'wget --passive-ftp -O - -t 1';
}
elsif($fetch_program =~ /lynx/i)
{
  $fetch_command = 'lynx -dump';
}
else
{
  die("Invalid remote program '$fetch_program' specified.");
}

$fetch_command .= $extra_args;

length($file)>0 or die("Please supply a local file.");
length($url)>0 or die("Please supply a URL.");

if(length($backup)==0)
{
  $backup = $file . '.backup';
}

my $tmp_file = "$tmp_dir/remote_update_tmp_" . time;

if(-f $file)
{
  $verbose and print STDERR "Downloading '$url'...";
  `$fetch_command '$url' > $tmp_file`;
  $verbose and print STDERR " done.\n";

  my @wc_out = split(/\s+/,`wc $tmp_file`);
  my $num_lines = $wc_out[1];

  @wc_out = split(/\s+/,`diff $tmp_file $file | wc`);
  my $diff_lines = $wc_out[1];

  if($num_lines == 0)
  {
    $verbose and print STDERR "Empty file downloaded from server.\n";
    `rm -f $tmp_file`;
  }

  elsif($diff_lines>0)
  {
    $verbose and print STDERR "Remote version of '$file' is different.\n";
    if($make_backup)
    {
      $verbose and print STDERR "Making backup '$backup'...";
      `cp $file $backup`;
      $verbose and print STDERR " done.\n";
    }
    $verbose and print STDERR "Updating local file...";
    `mv $tmp_file $file`;
    $verbose and print STDERR " done.\n";
  }

  else
  {
    $verbose and print STDERR "Remote file same as file '$file'; local file unchanged.\n";
    `rm -f $tmp_file`;
  }
}
else
{
  $verbose and print STDERR "Downloading '$url' to '$file'...";
  `$fetch_command '$url' > $file`;
  $verbose and print STDERR " done.\n";
}

exit(0);

__DATA__
syntax: remote_update.pl [OPTIONS] FILE URL

Downloads the file at URL to the local file FILE.  If FILE exists it is only overwritten
if the remote file at URL is different than the local FILE.

OPTIONS are:

-q: Quiet mode (default is verbose).
-nobackup: Do not make a backup copy (default makes a backup) of FILE.
-tmp DIR: Set the temporary directory to use to DIR (default is /tmp).
-wget: Use wget to retrieve URLs (this is the default).
-lynx: Use lynx to retrieve URLs (default is wget).


