#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libfile.pl";
require "$ENV{MYPERLDIR}/lib/libmap.pl";

use strict;

my $verbose        = 1;
my @files;
my $file_prefix    = 0;
my $overwrite      = 0;
my $skip_col       = undef;
my $force_uniq     = 0;
my $prefix         = undef;
my $convert_spaces = 0;
my @prefixes;
my $redundant      = 1;
my $get_file_prefix_indicator = '__GET_PREFIX_FROM_FILE_' . time . '_' . rand;

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
   elsif($arg eq '-p')
   {
      push(@prefixes, shift @ARGV);
   }
   elsif($arg eq '-pf')
   {
      push(@prefixes, $get_file_prefix_indicator);
   }
   elsif($arg eq '-s')
   {
      $convert_spaces = 1;
   }
   elsif($arg eq '-o')
   {
      $overwrite = 1;
   }
   elsif($arg eq '-k')
   {
      $skip_col = int(shift(@ARGV));
   }
   elsif($arg eq '-u')
   {
      $force_uniq = 1;
   }
   elsif($arg eq '-nr')
   {
      $redundant = 0;
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif(not(defined($prefix)))
   {
      $prefix = $arg;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$#files >= 0 or die("No files specified");

my $out = \*STDOUT;
my $tmp = undef;
my %seen;

foreach my $file (@files)
{
   open(FILE, $file) or die("Could not open file '$file' for reading");

   $verbose and print STDERR "Adjusting header for file '$file'.\n";

   $_ = <FILE>; chop;
   my @header = split(/\t/);
   for(my $i=0; $i<=$#header; $i++)
   {
      $verbose and print STDERR "$header[$i] --> ";
      if(not(defined($skip_col)) or $skip_col != $i+1)
      {
         my $combined_prefix = '';
         foreach my $pre (@prefixes)
         {
            # print STDERR "'$file' '$pre' --> ";
            if($pre eq $get_file_prefix_indicator)
            {
               $prefix = &remPathExt(&getPathSuffix($file));
            }
            else
            {
               $prefix = $pre;
            }
            # print STDERR "'$prefix'\n";

            if($redundant or not($header[$i] =~ /^$prefix/))
            {
               $combined_prefix .= $prefix;
            }
         }
         $header[$i] = $combined_prefix . $header[$i];

         if($convert_spaces)
         {
            $header[$i] =~ s/\s+/_/g;
         }

         if($force_uniq and exists($seen{$header[$i]}))
         {
            my $count = ++$seen{$header[$i]};
            $header[$i] .= '_' . $count;
         }

         $header[$i] = &removeIllegalChars($header[$i]);

         $seen{$header[$i]}++;
      }
      $verbose and print STDERR "$header[$i].\n";
   }

   if($overwrite)
   {
      $tmp = 'tmp_header_' . time . '_' . int(rand*1000);
      open($out, ">$tmp") or die("Internal error: could not open a temporary file");
   }

   print $out join("\t",@header), "\n";
   while(<FILE>)
     { print $out $_; }

   if($overwrite)
   {
      close($out);
      system("mv $tmp $file");
   }
}

exit(0);


__DATA__
syntax: header.pl [OPTIONS] FILE [FILE2 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-p PREFIX: Add the prefix PREFIX to each of the fields in the header.

-pf: Use the basename of the file as the prefix (after removing extensions)

-o: Overwrite the original file with a new one that has the new header.

-k RANGES: Do *not* add the prefix to the columns specified in ranges.

-u: Uniqueness guarantee.  Add a numeric prefix to fields that would otherwise not be unique.

-s: Convert spaces to a single underscore.

-nr: Non-redundant.  Don't add prefixes to fields that already have it as a
     substring.

