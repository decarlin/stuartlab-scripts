#!/usr/bin/perl

use strict;

my $verbose=1;
my $cmd;
my $develop_dir = "$ENV{HOME}/develop";
my $remote_dir = "$ENV{HOME}/leland";
my $input_directories = "$develop_dir/perl/frog/frog_directories.txt";
my $target_dir = "$develop_dir/frog";
my $local_archive = "$develop_dir/frog.zip";
my $remote_archive = "$remote_dir/frog.zip";
my $full=0;

my $do_perl=0;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '-full')
  {
    $full = 1;
  }
  elsif($arg eq '-perl')
  {
    $do_perl = 1;
    $local_archive = "$develop_dir/perl.zip";
    $remote_archive = "$remote_dir/perl.zip";
    $target_dir = "$develop_dir/perl";
  }
}

# If doing full backup, remove the frog archive.
if($full and -f $local_archive)
{
  `rm $local_archive`;
}

my @stats;
my $old_time=0;
if(-f $local_archive)
{
  # Get the original modification time of the archive:
  @stats = stat($local_archive);
  $old_time = $stats[9];
}
else
{
  $verbose and print STDERR "Performing full backup.\n";
}

# Zip the files up.
if($do_perl)
{
  $verbose and print STDERR "Zipping Frog Perl files.\n";
  $cmd = "cd $target_dir; " .
       "zipcode.pl $local_archive *";
}
else
{
  $verbose and print STDERR "Zipping Frog C++ files.\n";
  $cmd = "cd $target_dir; " .
       "zipcode.pl $local_archive " .
	  "-d $input_directories ";
}
`$cmd`;
$verbose and print STDERR "Done zipping Frog files.\n";

# Get the new modification time of the archive:
@stats = stat($local_archive);
my $new_time = $stats[9];

# Copy them to leland only if the archive has been modified
if($new_time>$old_time)
{
  $verbose and print STDERR "Copying to leland '$remote_archive'...";
  $cmd = "cp $local_archive $remote_archive";
  `$cmd`;
  $verbose and print STDERR " done.\n";
}
else
{
  $verbose and print STDERR "Nothing to copy to leland.\n";
}

__DATA__

syntax: frog2leland.pl [OPTIONS]

Zips up newly modified Frog files and transfers them to leland.  Reads
which directories to include from ~/develop/perl/frog/frog_directories.txt.

OPTIONS are:

-full: zip up everything in the frog directory (do not check modification times)
-perl: zip up Perl sources instead of C++ sources.

