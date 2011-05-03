#!/usr/bin/perl

use strict;

my $verbose = 1;
my $develop_dir = "$ENV{HOME}/develop";
my $target_dir = "$ENV{MYPERLDIR}/lib/frog";
my $perl_dir = "$ENV{MYPERLDIR}/lib/perl";
my $remote_dir = "$ENV{HOME}/leland";
my $remote_archive = "$ENV{MYPERLDIR}/lib/frog.zip";
my $local_archive = "$develop_dir/frog.zip";
my $local_file = '';
my $do_perl=0;

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
  elsif($arg eq '-local')
  {
    $local_file = shift @ARGV;
  }
  elsif($arg eq '-perl')
  {
    $do_perl = 1;
    $local_archive = "$develop_dir/perl.zip";
    $remote_archive = "$remote_dir/perl.zip";
    $target_dir = "$develop_dir/perl";
  }
}

my $real_local_archive=$local_archive;
if(length($local_file)<1)
{
  my $mv_cmd = "mv $remote_archive $local_archive";
  $verbose and print STDERR "Moving '$remote_archive' to '$local_archive'...";
  `$mv_cmd`;
  $verbose and print STDERR " done.\n";
}
else
{
  $local_archive = $local_file;
}

my $unzip_cmd = "cd $target_dir; unzip -o $local_archive";
$verbose and print STDERR "Installing CygWin sources under $target_dir.\n";
system($unzip_cmd);
$verbose and print STDERR "Done installing CygWin sources.\n";

if(not($do_perl))
{
  # Make the Makefiles compatible for linux/solaris
  my $makefile_fix = "cd $target_dir; " .
                   "ziplist.pl $local_archive | " .
                   "apply.pl -v -i - -o -suffix Makefile ar2ld.pl";
  $verbose and print STDERR "Converting Makefiles from CygWin to Frog.\n";
  system($makefile_fix);
  $verbose and print STDERR "Done converting Makefiles.\n";
}

# Make the frog archive more current than anything we modified above (like the Makefiles)
$verbose and print STDERR "Making the archive more current than any modifications...";
`touch $real_local_archive`;
$verbose and print STDERR " done.\n";

exit(0);

__DATA__
syntax: leland2frog.pl

OPTIONS are:

-q: quiet mode
-local FILE: Read CygWin archive from FILE instead of fetching over network.
-perl: Update Perl instead of C++ sources.

