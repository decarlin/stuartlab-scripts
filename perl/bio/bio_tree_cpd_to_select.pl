#! /usr/bin/perl

#usage: bio_tree_cpd_to_select.pl <tree cpd file> <gene_rel_name>

#----------------------------------------------------------------
# load the settings
#----------------------------------------------------------------
if (length($ARGV[0]) == 0) { $settings_file = "settings"; } else { $settings_file = $ARGV[0]; }

open(SETTINGS, "<$settings_file") or die "could not open settings";

while (<SETTINGS>)
{
	chop;
   ($id, $value) = split(/=/, $_, 2);

	$settings{$id} = $value;
}

#---------------------------------------------------------------------------
# parameters
#---------------------------------------------------------------------------
$startSearchStr = "probability[(]" . $settings{"expressions_rel_name"} . "[.]exp_level[ ][|]";
$probabilitySearchStr = "probability[ ][(]" . $settings{"expressions_rel_name"} . "[.]exp_level[)]";

$tree_cpd_file = $settings{"tree_cpd_file"};
if ($ARGV[0] ne "") { $tree_cpd_file = $ARGV[0]; }
open(TREE_CPD, "<$tree_cpd_file") or die "could not open $tree_cpd_file";

$gene_rel_name = $settings{"gene_rel_name"};
if ($ARGV[1] ne "") { $gene_rel_name = $ARGV[1]; }

$expression_rel_name = $settings{"expressions_rel_name"};

$ordinal = $settings{"ordinal"};

$out_selects = "gene_selects"; 
open(OUT_SELECTS, ">$out_selects") or die "could not open OUT_SELECTS";

#print $gene_rel_name . "\n";

#---------------------------------------------------------------------------
# trim leading spaces
#---------------------------------------------------------------------------
sub trim_leading_spaces
{
  $word = $_[0];

  if ($word =~ /^[\s]+(.*)/) { return $1; }
  else { return $word; }
}

#---------------------------------------------------------------------------
# parse the tree cpd
#---------------------------------------------------------------------------
$SPLIT_1 = 0;
$SPLIT_2 = 1;
$IN_SPLIT_1 = 2;
$IN_SPLIT_2 = 3;
$PROBABILITY = 4;
$NONE = 5;

$STATUS_SPLIT = 0;
$STATUS_PROBABILITY = 1;
$STATUS_POP = 2;
$STATUS_NONE = 3;

$row_num = 0;
$now_parsing = 0;
$mode = $NONE;
$stack_num = 0;

while(<TREE_CPD>)
{
   chop;

   $trimmed = trim_leading_spaces($_);
   $_ = $trimmed;

   if (/${startSearchStr}/) { $now_parsing = 1; }

   $status = $STATUS_NONE;
   if (/split[ ]on[ ]condition/) { $status = $STATUS_SPLIT; }
   if (/${probabilitySearchStr}/) { $status = $STATUS_PROBABILITY; }
   if ($_ eq "}") { $status = $STATUS_POP; }

   if ($now_parsing == 1)
   {
	 $stack_mode = $NONE;
	 if ($stack_num > 0) { $stack_mode = $stack_modes[$stack_num - 1]; }

	 #print $status . " " . $stack_mode . " - LL" . $_ . "LL\n";

	 if ($status == $STATUS_SPLIT)
	 {
       #print "splitting $_\n";

	   @conditions = split(/\./);
	   $num_conditions = @conditions;

	   $conditions[$num_conditions-1] =~ /([^ ]+)[^\"]+"([^\"]+)"/;

	   $stack_attributes[$stack_num] = $1;
	   $stack_conditions[$stack_num] = $2;
       $stack_modes[$stack_num] = $SPLIT_1;
       $stack_num++;
	 }
     elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_1)
     {
       $_ =~ /([^ ]+)/;

	   $stack_values[$stack_num - 1] = $1;
       $stack_modes[$stack_num - 1] = $IN_SPLIT_1;

       #print "split1=$stack_values[$stack_num - 1] \n";
     }
     elsif ($status == $STATUS_NONE && $stack_mode == $SPLIT_2)
     {
       $_ =~ /([^ ]+)/;

       if ($1 eq "true")
       {
 	      $stack_values[$stack_num - 1] = $1;
          $stack_modes[$stack_num - 1] = $IN_SPLIT_2;

          #print "split2=$stack_values[$stack_num - 1] \n";
       }
     }
     elsif ($status == $STATUS_POP)
     {
       if ($stack_modes[$stack_num - 1] == $IN_SPLIT_1)
       {
         #print "popping from $stack_attributes[$stack_num - 1]=$stack_conditions[$stack_num - 1]$stack_values[$stack_num - 1]\n";
         $stack_modes[$stack_num - 1] = $SPLIT_2;
       }
       elsif ($stack_modes[$stack_num - 1] == $IN_SPLIT_2)
       {
         #print "popping from " . $stack_attributes[$stack_num - 1] . "=" . $stack_conditions[$stack_num - 1] . "=" . $stack_values[$stack_num - 1] . "\n";

         $stack_num--;

         if ($stack_num == 0) { exit; }
       }
     }
     elsif ($status == $STATUS_PROBABILITY)
     {
       #print "probability $_\n";

       $where_clause = "";
       $first = 1;
       for ($i = 0; $i < $stack_num; $i++)
       {
         print $stack_attributes[$i] . "\t" . $stack_conditions[$i] . "\t" . $stack_values[$i] . "\t\n";

		 if ($first == 0) { $where_clause = $where_clause . " and "; }
		 elsif ($first == 1) { $where_clause = "where "; $first = 0; }

		 if ($stack_values[$i] eq "false") { $where_clause = $where_clause . $stack_attributes[$i] . "!='$stack_conditions[$i]' "; }
		 elsif ($stack_values[$i] eq "true") { $where_clause = $where_clause . $stack_attributes[$i] . "='$stack_conditions[$i]' "; }
       }
	   
       print OUT_SELECTS "select gene_name from $gene_rel_name $where_clause\n"; 
       #print "select gene_name from $gene_rel_name $where_clause\n"; 
     }
   }
}
