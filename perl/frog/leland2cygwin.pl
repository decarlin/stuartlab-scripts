#!/usr/bin/perl

use strict;

my $verbose = 1;
my $develop_dir = "$ENV{HOME}/develop";
my $target_dir = "$ENV{MYPERLDIR}/lib/frog";
my $perl_dir = "$ENV{MYPERLDIR}/lib/perl";
my $remote_dir = "$ENV{HOME}/leland";
my $remote_archive = "$ENV{MYPERLDIR}/lib/frog.zip";
my $local_archive = "$develop_dir/frog.zip";
my $local_file='';
my $do_perl=0;
my $delete=0;

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
  elsif($arg eq '-delete' or $arg eq '-remove')
  {
    $delete = 1;
  }
}

# Remove all the non-src and non-RCS files
if(not($do_perl) and $delete)
{
  my $rm_cmd = "cd $target_dir; " .
             "cygwin_directories.pl | " .
	     "apply.pl -d - -batch -names 'rmcode.pl -f -i -'";
  $verbose and print STDERR "Removing *all* non-src and non-RCS files\n";
  `$rm_cmd`;
  $verbose and print STDERR "Done removing non-src and non-RCS files.\n";
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
$verbose and print STDERR "Installing frog sources under $target_dir.\n";
system($unzip_cmd);
$verbose and print STDERR "Done installing frog sources.\n";

if(not($do_perl))
{
  my $makefile_fix = "cd $target_dir; " .
                   "ziplist.pl $local_archive | " .
                   "apply.pl -v -i - -o -suffix Makefile ld2ar.pl";
  $verbose and print STDERR "Converting Makefiles from Frog to CygWin.\n";
  system($makefile_fix);
  $verbose and print STDERR "Done converting Makefiles.\n";

  my $froglinks_cmd = "frog_links.pl";
  $verbose and print STDERR "Updating frog links.\n";
  system($froglinks_cmd);
  $verbose and print STDERR "Done updating frog links.\n";
}

# Make the frog archive more current than anything we modified above (like the Makefiles)
$verbose and print STDERR "Making the archive more current than any modifications...";
`touch $real_local_archive`;
$verbose and print STDERR " done.\n";

exit(0);

__DATA__
syntax: leland2cygwin.pl [OPTIONS]

OPTIONS are:

-q: quiet mode
-local FILE: Read Frog archive from FILE instead of fetching over network.
-perl: Update Perl instead of C++ sources.


