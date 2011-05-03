#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

my $dir     = &getMapDir('root');
my $archive = &getMapDir('backup') . '/map.zip';
my $files = '';
$files .= `cd $dir; find . -name "Makefile*" -print | grep -v Backup`;
$files .= `cd $dir; find . -name "genelist*" -print | grep -v Backup`;
$files .= `cd $dir; find . -name "README*" -print | grep -v Backup`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.maprc\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.lst\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.pl\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.map\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.mak\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.run\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.eval\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.att\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.url\$'`;
$files .= `cd $dir; find . -print | grep -v Backup | grep '\\.xml\$'`;
# print STDERR "$files\n";
# exec("echo '$files' | zip $archive -@");
# `cd $dir; echo '$files' | zip $archive -@`;

open(PIPE, "| zip $archive -@") or die("Could not zip files to '$archive'");

my @files = split(/\n/,$files);

print STDERR join("\n", @files), "\n";

print STDERR "Zipping files to archive '$archive'.\n";

foreach my $file (@files)
{
   print PIPE "$file\n";
}
close(PIPE);

# Add Perl scripts to the archive.
# $dir   = "$ENV{HOME}/develop";
# $files = `cd $dir; find perl -print`;
# print STDOUT "$files\n";
# `cd $dir; echo '$files' | zip -u $archive -@`;


