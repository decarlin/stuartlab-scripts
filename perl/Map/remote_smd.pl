#!/usr/bin/perl

##############################################################################
##############################################################################
##
## remote_smd.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "$ENV{MYPERLDIR}/lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my $remote_dir = shift @ARGV;

my $suffix     = shift @ARGV;

my $cmd        = "cd $remote_dir;";

my @archives   = &getAllFilesRecursively(0, ($remote_dir));

foreach my $archive (@archives)
{
   my $base_name = &getPathSuffix($archive);

   print STDERR "archive='$archive' --> base_name='$base_name'\n";

   if($archive =~ /tar.gz$/)
   {
      system("ls $archive");

      print STDERR "Unzipping and untarring '$archive'.\n";
      system("cd $remote_dir; gunzip -c ../$archive | tar -xf -; cd ..");
      print STDERR "Done unzipping and untarring.\n";
   }
   elsif($archive =~ /.tar$/)
   {
      print STDERR "Untarring '$base_name'.\n";
      system("cd $remote_dir; tar -xf ../$archive; cd ..");
      print STDERR "Done untarring.\n";
   }

   my @dirs = &getAllDirs($remote_dir);

   foreach my $dir (@dirs)
   {
      my @files = split("\n", `find $dir -print | grep '\.xls\$'`);

      push(@files, split("\n", `find $dir -print | grep '\.meta\$'`));

      foreach my $file (@files)
      {
         my $base_name = &getPathSuffix($file);

         system("mv $file $remote_dir/$base_name");
         print STDERR "'$file' moved to $remote_dir/$base_name.\n";
         system("touch -r $archive $remote_dir/$base_name");
      }

      print STDERR "Removing directory '$dir'.\n";
      system("rm -rf $dir");
   }
}


exit(0);


__DATA__
syntax: remote_smd.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).



