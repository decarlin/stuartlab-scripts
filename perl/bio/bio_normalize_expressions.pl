#! /usr/bin/perl
#usage: normalize_expressions.pl

require "$ENV{MYPERLDIR}/lib/format_number.pl";

#---------------------------------------------------------------------------------------------------------------------------
# input: 
#    normalize_expressions - the actual expression file
#    num_headings - the number of column headers that the expression file has BEFORE the actual data columns
# output:
#    the same expression file, normalized
#---------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open SETTINGS";
while (<SETTINGS>)
{
  chop;
  ($id, $value) = split(/=/, $_, 2);

  $settings{$id} = $value;
}

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
$normalize_expressions = $settings{"normalize_expressions"};
open(EXPRESSIONS, "<$normalize_expressions") or die "could not open EXPRESSIONS";

$num_headings=$settings{"num_headings"};

open(OUT_NORMAILIZED, ">$normalize_expressions.norm") or die "could not open OUT_NORMAILIZED";

# ANOTHER PARAMETER: FIX THE SPLIT BELOW BETWEEN THE FIGURE FILE AND THE RAW FILE

#---------------------------------------------------------------------------
# get the number of features for all files
#---------------------------------------------------------------------------
$row_num = 0;
$experiments_num = -1;
while(<EXPRESSIONS>)
{
   chop;

   if ($num_headings == 1) { ($h[0], $gene_data) = split(/\t/, $_, 2); }
   elsif ($num_headings == 2) { ($h[0], $h[1], $gene_data) = split(/\t/, $_, 3); }
   elsif ($num_headings == 3) { ($h[0], $h[1], $h[2], $gene_data) = split(/\t/, $_, 4); }
   elsif ($num_headings == 4) { ($h[0], $h[1], $h[2], $h[3], $gene_data) = split(/\t/, $_, 5); }
   elsif ($num_headings == 5) { ($h[0], $h[1], $h[2], $h[3], $h[4], $gene_data) = split(/\t/, $_, 6); }
   elsif ($num_headings == 6) { ($h[0], $h[1], $h[2], $h[3], $h[4], $h[5], $gene_data) = split(/\t/, $_, 7); }

   @gene_data = split(/\t/, $gene_data);

   if ($experiments_num == -1) { $experiments_num = @gene_data; }

   #print "$experiments_num -- @gene_data\n";

   #-----------------
   # compute the mean
   #-----------------
   $sum = 0;
   $numMissing = 0;
   $num_experiments_used = 0;
   for ($i = 0; $i < $experiments_num; $i++)
   {
     $num_experiments_used++;
     if ($gene_data[$i] eq "" || $gene_data[$i] eq "#VALUE!")
     {
       $numMissing++;
     }
     else
     {
       $sum += $gene_data[$i];
     }
   }

   if ($numMissing < $experiments_num)
   {
     $mean = $sum / ($num_experiments_used - $numMissing);
   }
   else
   {
     $mean = 0;
   }

   #---------------------
   # compute the variance
   #---------------------
   $sum = 0;
   $numMissing = 0;
   $num_experiments_used = 0;
   for ($i = 0; $i < $experiments_num; $i++)
   {
     $num_experiments_used++;
     if ($gene_data[$i] eq "" || $gene_data[$i] eq "#VALUE!")
     {
       $numMissing++;
     }
     else
     {
       $sum += ($gene_data[$i] - $mean) * ($gene_data[$i] - $mean);
     }
   }

   if ($numMissing < $experiments_num)
   {
     $variance = $sum / ($num_experiments_used - $numMissing);
   }
   else
   {
     $variance = 0;
   }
   $std = sqrt $variance;

   #print "variance=$variance std=$std |$h[0]| mean=$mean missing=$numMissing num=$experiments_num\n";

   #--------------------------
   # print the normalized data
   #--------------------------
   for ($headings = 0; $headings < $num_headings; $headings++)
   {
	 print OUT_NORMAILIZED "$h[$headings]\t";
   }

   for ($i = 0; $i < $experiments_num; $i++)
   {
     #print "gene_data[$i]=$gene_data[$i]\n";
     if ($gene_data[$i] =~ /\S/)
     {
       if ($std > 0)
       {
	 $to_print_value = ($gene_data[$i] - $mean) / $std;

	 $to_print_value = format_number($to_print_value, 3);

	 print OUT_NORMAILIZED $to_print_value;
	 print OUT_NORMAILIZED "\t";
       }
       else
       {
	 print OUT_NORMAILIZED "\t";
       }
     }
     else
     {
       $total_missing++;
       print OUT_NORMAILIZED "\t";
     }
   }
   print OUT_NORMAILIZED "\n";

   $row_num++;
   #if ($row_num == 2) { last; }
}
print "total_missing=$total_missing\n";
