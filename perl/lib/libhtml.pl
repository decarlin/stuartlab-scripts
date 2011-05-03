#!/usr/bin/perl


# Note: if you are including this file, and you want to convert HTML entities like space->%20 (or you want to convert back), then there is a standard perl module that does this:  use URI::Escape;



sub html2table($$$$)
{
   my ($page, $keep_blanks, $keep_format, $keep_links) = @_;

   my @keep_format_chars  = split(" ", "br b font sup pre");
   my $delim         = "\t";

   $page =~ s/<![^>]*>//gi;

   $page =~ s/<\/html[^>]*>//gi;

   $page =~ s/<\/body[^>]*>//gi;

   my @lines = split(/\<table[^>]*>/i, $page);

   my @tables;

   for(my $t = 1; $t < @lines; $t++)
   {
      my @table;

      $lines[$t] =~ s/<\/table[^>]*>//gi;

      my @rows = split(/<tr[^>]*>/i, $lines[$t]);

      foreach my $row (@rows)
      {
         if($keep_blanks or $row =~ /<td/i)
         {
            $row =~ s/<td[^>]*>/$delim/gi;
            $row =~ s/\n//g;
            $row =~ s/<\/td[^>]*>//gi;
            $row =~ s/<\/tr[^>]*>//gi;

            if(not($keep_format))
            {
               foreach my $keep_format_char (@keep_format_chars)
               {
                  $row =~ s/<$keep_format_char[^>]*>/ /gi;
                  $row =~ s/<\/$keep_format_char[^>]*>//gi;
               }
            }

            if(not($keep_links))
            {
               # Get rid of links
               $row =~ s/<a\s+href\s*=[^>]*>([^<]*)<\/a[^>]*>/$1/gi;

               # Get rid of images
               $row =~ s/<\s*img[^>]*>//gi;

               # Get rid of labels
               $row =~ s/<a\s+Name\s*=[^>]*>//gi;
            }
            if($keep_blanks or $row =~ /\S/)
            {
               my @row = split($delim, $row);
               push(@table, \@row);
            }
         }
      }
      if($keep_blanks or scalar(@table) > 0)
      {
         push(@tables, \@table);
      }
   }
   return \@tables;
}


#-------------------------------------------------------------------------------
# $string getHtmlTableRow(\@list ; $color)
#-------------------------------------------------------------------------------
sub getHtmlTableRow(\@;$) {
    # color is an OPTIONAL second argument for the cell color for each cell on this row

   my ($list,$color) = @_;
   $list = defined($list) ? $list : [split];

   my $colorStr = '';
   if (defined($color) and $color) {
       $colorStr = qq{ BGCOLOR=\"$color\"};
   }

   my $string = "<TR${colorStr}>\n";

   foreach my $entry (@{$list}) {
      $string .= "     <TD>${entry}</TD>\n";
   }
   $string .= "</TR>";

   return $string;
}


#-------------------------------------------------------------------------------
# $string getHtmlTableRow(\@list ; $rowAttributes $colAttributes)
#-------------------------------------------------------------------------------
sub getFormattedHtmlTableRow(\@;$$) {
    # $rowAttr: Row attributes: something that is done to the TR tag (text that goes in the <TR ... >
    # $cellAttr: Cell attributes: something that is done to each cell (text that goes in the <TD ... >

   my ($list,$rowAttr,$cellAttr) = @_;
   $list = defined($list) ? $list : [split];

   if (!defined($rowAttr) || (scalar($rowAttr)>0)) { $rowAttr = ''; } else { $rowAttr = ' ' . $rowAttr; } # put a space before the attribute, if there IS one defined
   if (!defined($cellAttr) || (scalar($cellAttr)>0)) { $cellAttr = ''; } else { $cellAttr = ' ' . $cellAttr; } # put a space before the attribute, if there IS one defined

   my $string = "<TR${rowAttr}>\n"; # <-- the space gets added above so that there is a space after the TR

   foreach my $entry (@{$list}) {
      $string .= "     <TD${cellAttr}>${entry}</TD>\n";
   }
   $string .= "</TR>";

   return $string;
}





1
