#!/usr/bin/perl

use strict;

my $verbose=1;
my $cmd;
my $develop_dir = "$ENV{HOME}/develop";
my $remote_dir = "$ENV{HOME}/leland";
my $cygwin_dirs = "$develop_dir/perl/frog/cygwin_directories.pl";
my $output_list = "$develop_dir/cygwin_files.txt";
my $local_archive = "$develop_dir/frog.zip";
my $target_dir = "$develop_dir/frog";
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

# Get the original modification time of the archive:
my @stats;
my $old_time=0;
if(-f $local_archive)
{
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
  $verbose and print STDERR "Zipping CygWin Perl files.\n";
  $cmd = "cd $target_dir; " .
       "zipcode.pl $local_archive *";
}
else
{
  $verbose and print STDERR "Zipping CygWin C++ files.\n";
  $cmd = "cd $develop_dir/frog; " .
       "$cygwin_dirs | " .
       "zipcode.pl $local_archive " .
	  "-d - ";
}
`$cmd`;
$verbose and print STDERR "Done zipping CygWin files.\n";

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

syntax: cygwin2leland.pl [OPTIONS]

Zips up newly modified CygWin files and transfers them to leland.  Reads
which directories to include by calling ~/develop/perl/frog/cygwin_directories.pl.
Files in src/ and RCS/ directories are not included.

OPTIONS are:

-full: zip up everything in the CygWin directory (do not check modification times)
-perl: zip up Perl sources instead of C++ sources.

