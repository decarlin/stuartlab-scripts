#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;

my $verbose = 1;
my @files;
my $col1 = 1;
my $col2 = 2;
my $delim = "\t";
my $dos = 0;
my $body = 0;
my @lists_desc;
my @header;
my $headers = 1;
my @desc_names;
my %desc_urls;
my @desc_colors;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k1')
   {
      $col1 = int(shift @ARGV);
   }
   elsif($arg eq '-k2')
   {
      $col2 = int(shift @ARGV);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-nh')
   {
      $headers = 0;
   }
   elsif($arg eq '-dos')
   {
      $dos = 1;
   }
   elsif($arg eq '-body')
   {
      $body = 1;
   }
   elsif($arg eq '-desc')
   {
      $arg = shift @ARGV;
      print STDERR "Reading in descriptions...";
      open(DESC, $arg) or die("Could not open descriptions file '$arg'");
      my %desc;
      my $line = 0;
      while(<DESC>)
      {
         $line++;
         my @tuple = split("\t");
           chomp($tuple[$#tuple]);
         if($headers and scalar(@header) == 0)
         {
            $verbose and print STDERR "Header for file '$arg': ", join(",",@header), "\n";
            @header = @tuple;
         }
         elsif($line > $headers)
         {
            my $key = shift @tuple;
            $desc{$key} = \@tuple;
         }
      }
      push(@lists_desc, \%desc);

      print STDERR " done.\n";
      close(DESC);
   }
   elsif($arg eq '-name')
   {
      $arg = shift @ARGV;
      push(@desc_names, $arg);
   }
   elsif($arg eq '-url')
   {
      $arg = shift @ARGV;
      my @tuple = split(',,', $arg);
      if(scalar(@tuple) == 4)
      {
         my ($i, $j, $url_prefix, $url_suffix) = @tuple;
         my @url = ($url_prefix, $url_suffix);
         $desc_urls{$i, $j} = \@url;
      }
      else
      {
         die("URL option wrong format, need a comma-seperated tuple");
      }
   }
   elsif($arg eq '-color')
   {
      $arg = shift @ARGV;
      push(@desc_colors, $arg);
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$col1--;
$col2--;

if($#files == -1)
{
   push(@files,'-');
}

if(scalar(@desc_names) > 0)
{
   splice(@header, 1, 0, 'Description Name');
}

foreach my $file (@files)
{
   my $sets = &setListsRead($file, $delim, $col1, $col2);

   # &setsPrint($sets, \*STDOUT);

   foreach my $set_key (keys(%{$sets}))
   {
      my $list = $$sets{$set_key};

      my $file_name = $set_key . '.html';
      if($dos)
      {
         $file_name =~ s/\s+/_/g;
         $file_name =~ tr/A-Z/a-z/;
      }
      open(HTML, ">$file_name") or die("Could not open html file '$file_name'");
      if($body)
      {
         print HTML "<html><body>\n";
      }
      print HTML "<table border=\"true\">\n";
      if(scalar(@header) > 0)
      {
         print HTML "   <tr>\n";
         foreach my $field (@header)
         {
            print HTML "      <td>$field</td>\n";
         }
         print HTML "   </tr>\n";
      }
      foreach my $element (@{$list})
      {
         # Get descriptions for this element.
         my @desc;
         for(my $i = 0; $i < scalar(@lists_desc); $i++)
         {
            my $desc = $lists_desc[$i];
            if(exists($$desc{$element}))
            {
               push(@desc, $$desc{$element});
            }
            else
            {
               push(@desc, undef);
            }
         }

         print HTML "   <tr>\n      <td>$element</td>\n";

         if(scalar(@desc) > 0)
         {
            for(my $i = 0; $i < scalar(@desc); $i++)
            {
               my $desc_i    = defined($desc[$i]) ? $desc[$i] : ['&nbsp;'];
               my $desc_name = $i < scalar(@desc_names) ? $desc_names[$i] : '&nbsp;';

               if($i > 0)
               {
                  print HTML "   <tr>\n      <td>&nbsp;</td>\n";
               }

               &printTableData(\*HTML, $desc_name, $i, $desc_i, \%desc_urls);

               if($i > 0)
               {
                  print HTML "   </tr>\n";
               }
            }
         }
         else
         {
            for(my $i = 1; $i < scalar(@header); $i++)
            {
               print HTML "      <td>&nbsp;</td>\n";
            }
            print HTML "   </tr>\n";
         }
      }
      print HTML "</table>\n";
      if($body)
      {
         print HTML "</html></body>\n";
      }
      close(HTML);
   }
}

exit(0);

##-----------------------------------------------------------------------------
## void printTableData (\*FILE HTML, $string desc_name, $int i, 
##                      \@desc_tuple, \%desc_urls, \@desc_colors);
##-----------------------------------------------------------------------------
sub printTableData
{
   my ($html, $desc_name, $i, $desc_tuple, $desc_urls, $desc_colors) = @_;
   # my $color = length(@{$desc_colors} > $i) ? $$desc_colors[$i] : undef; 
   my $color = undef;

   if(defined($desc_name) and $desc_name =~ /\S/)
   {
      if(defined($color))
         { print $html "      <td bgcolor=\"$color\">$desc_name</td>\n"; }
      else
         { print $html "      <td>$desc_name</td>\n"; }
   }
   for(my $j = 0; $j < scalar(@{$desc_tuple}); $j++)
   {
      my $item = $$desc_tuple[$j];
      my ($url_prefix, $url_suffix) = ('', '');
      my ($i_, $j_) = ($i + 1, $j + 1);
      if(exists($$desc_urls{$desc_name,$j_}))
      {
         ($url_prefix, $url_suffix) = @{$$desc_urls{$desc_name,$j_}};
      }
      elsif(exists($$desc_urls{$i_,$j_}))
      {
         ($url_prefix, $url_suffix) = @{$$desc_urls{$i_,$j_}};
      }
      if(defined($color))
         { print $html "      <td bgcolor=\"$color\">", &htmlString($item, $url_prefix, $url_suffix), "</td>\n"; }
      else
         { print $html "      <td>", &htmlString($item, $url_prefix, $url_suffix), "</td>\n"; }
   }
}

##-----------------------------------------------------------------------------
## $string htmlString ($string text)
##-----------------------------------------------------------------------------
sub htmlString
{
   my ($text, $url_prefix, $url_suffix) = @_;
   $text = not(defined($text)) ? '' : $text;

   my $result;
   if($text =~ /\S/)
   {
      if($url_prefix =~ /\S/ or $url_suffix =~ /\S/)
      {
         $result = '<a href="' . $url_prefix . $text . $url_suffix . '">' . $text . '</a>';
      }
      else
      {
         $result = $text;
      }
   }
   else
   {
      $result = '&nbsp;';
   }

   return $result;
}

__DATA__
syntax: lists2htmltable.pl [OPTIONS] FILE1 [FILE2 ...]

On each line the input files have:

        ELEMENT_NAME <tab> SET_NAME

The script reads all the sets and outputs a seperate
html file for each set.  The file name given is SET_NAME.html
for each set.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-k1 COL: Set the element name column to COL (default is 1).

-k2 COL: Set the set name column to COL (default is 2).

-dos: Make the output file names DOS-like (convert all 
      SET_NAMEs to lower-case and replace spaces with underscores).

-body: put <html><body> ... </html></body> around the tables.

-desc TABFILE: File that contains descriptions (multiple files can be
               supplied each with their own -desc flag).

-name NAME: Give a name to a description.  This is applied in the same
            order as the files supplied by the -desc flags.

-url I,,J,,PREFIX,,SUFFIX: Assign a url to the Ith description and the Jth
                           tuple in that description.  When the Jth entry
                           is printed it will be preceded by PREFIX and
                           followed by SUFFIX.  The index I selects a description
                           in the same order as the -desc are supplied (the
                           first description has index 1).  Alternatively, if the
                           description has been given a name (i.e. with the -name
                           flag), the name can be given instead of I.

                           *NOTE* make sure 2 commas seperate
                           the entries (this is to avoid conflicts with URLs
                           containing single commas).

-nh: description files do *not* contain header lines (default assumes
     all input files have them).


TODO:

add organism as another column.


