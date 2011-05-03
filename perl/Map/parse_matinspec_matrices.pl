#!/usr/bin/perl

# Usage:
# parse_matinspec_matrices.pl matinspec_file output_file promoter_file

$tf_file = shift(@ARGV);
$out_file = shift(@ARGV);
$promot_file = shift(@ARGV);

open(IN, "$tf_file") || die "can't open $tf_file";
open(OUT, ">$out_file") || die "can't open $out_file";

print OUT "<Motifs SeqFile=\"$promot_file\">\n";

while($line = <IN>) {
    if ($line=~/^(\w)\$((\w|\d)+\_(\w|\d)+)\s+\((.+)\)/) {
         $factor =      $2;
         $species =     $1;
         $description = $5;
         $description =~ s/\s+$//;
         #good, the next 4 lines should be the 4 columns of
         #the matrix

         $a_line = <IN>;
         chop($a_line);
         chop($a_line);
         @a_arr = split(/\//,$a_line);

         $c_line = <IN>;
         chop($c_line);
         chop($c_line);
         @c_arr = split(/\//,$c_line);

         $g_line = <IN>;
         chop($g_line);
         chop($g_line);
         @g_arr = split(/\//,$g_line);

         $t_line = <IN>;
         chop($t_line);
         chop($t_line);
         @t_arr = split(/\//,$t_line);

         #print "\n$factor $description\n";

         #now put it together
         @pssm = ();
         $consensus = "";

         foreach $a (@a_arr) {
             $min_score = -1000;

             $a = int($a * 10);
             if ($a > $min_score) {
                 $consensus_ch = "A";
                 $min_score = $a;
             }

             $c = int(shift(@c_arr) * 10);
             if ($c > $min_score) {
                 $consensus_ch = "C";
                 $min_score = $c;
             }

             $g = int(shift(@g_arr) * 10);
             if ($g > $min_score) {
                 $consensus_ch = "G";
                 $min_score = $g;
             }

             $t = int(shift(@t_arr) * 10);
             if ($t > $min_score) {
                 $consensus_ch = "T";
                 $min_score = $t;
             }

             $consensus = $consensus.$consensus_ch;

             push(@pssm, "$a;$c;$g;$t"); 
         }

         #print "$consensus\n";
         print OUT "<Motif Consensus=\"$consensus\" Source=\"TRANSFAC\" Name = \"$factor\" Description = \"$description\">\n";
         print OUT "\t<Weights>\n";
         $pos = 0;
         foreach $pos_line (@pssm) {
             print OUT "\t\t<Position Num=\"$pos\" Weights=\"$pos_line\"></Position>\n";
             $pos++;
         }
         print OUT "\t</Weights>\n";
         print OUT "</Motif>\n";


    } else {
         #print "$line";
    }
}

print OUT "</Motifs>\n";
