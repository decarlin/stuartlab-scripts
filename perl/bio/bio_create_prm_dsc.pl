#! /usr/bin/perl

#-----------------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    BCPD_prefix = the prefix of all files
#    BCPD_dir = the directory of the dsc file
#    BCPD_num_relations = the number of relations
#    BCPD_relation_i = the name of the i-th relation
#    BCPD_relation_num_key_attributes_i = the number of key attributes of the i-th relation
#    BCPD_relation_key_attribute_i_j = the actual key attributes
#    BCPD_relation_num_foreign_key_attributes_i = the number of foreign key attributes of the i-th relation
#    BCPD_relation_foreign_key_attribute_i_j = the actual foreign key attributes
#    BCPD_relation_foreign_key_type_attribute_i_j = the NUMBER of the relation name that the foreign key points to
#    BCPD_relation_num_attributes_i = the number of attributes of the i-th relation
#    BCPD_relation_attribute_i_j = the actual attributes
#    BCPD_relation_attribute_additional_info_i_j = the additional info of the actual attributes
#    BCPD_relation_type_attributes_i_j = the type of the actual attribute (continuous, int, or char(xxx))
#    BCPD_relation_enum_attributes_i_j = an enumeration in the form "val1", "val2" applicable in the case of a "char" type or 1,10 in case of int (the start)
#
#    BCPD_relation_prob_attributes_i - the number of probability attributes for the i-th relation
#    BCPD_relation_prob_attribute_i_j - the j-th attribute of the i-th relation
#    BCPD_relation_prob_attribute_parents_i_j - the parents of the j-th attribute of the i-th relation
#    BCPD_relation_prob_attribute_cpd_type_i_j - the type of the cpd of the j-th attribute of the i-th relation
#    BCPD_relation_prob_attribute_cpd_type_dsc_i_j - the description (for discrete, for nonlinear cpds) of the cpd for the i-th relation of i-th relation
# output:
#    creates the prm dsc file
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";

my %settings = load_settings($ARGV[0]);

my $prefix = $settings{"BCPD_prefix"};
my $dir = $settings{"BCPD_dir"};

my @join_from_relation;
my @join_to_relation;
my @join_from_key;
my @join_to_key;
my @join_name;
my $join_counter = 0;

my $output_file = "$dir/${prefix}_0.dsc";
open(DSC_FILE, ">$output_file");

sub print_prm_header
{
  print DSC_FILE "prm \"Exp_real\"\n";
  print DSC_FILE "{\n";
  print DSC_FILE "format is \"PRMFormat\";\n";
  print DSC_FILE "version is 0.00;\n";
  print DSC_FILE "creator is \"es\";\n";
  print DSC_FILE "}\n";
  print DSC_FILE "\n";
}

sub print_relations
{
  my $num_relations = $settings{"BCPD_num_relations"};
  my $i;
  my $j;

  for ($i = 1; $i <= $num_relations; $i++)
  {
	my $relation_i = $settings{"BCPD_relation_$i"};

	print DSC_FILE "relation $relation_i\n";
	print DSC_FILE "{\n";

	my $relation_num_key_attributes_i = $settings{"BCPD_relation_num_key_attributes_$i"};
	for ($j = 1; $j <= $relation_num_key_attributes_i; $j++)
	{
	  my $relation_key_attribute_i_j = $settings{"BCPD_relation_key_attribute_${i}_$j"};

	  print DSC_FILE "kattribute $relation_key_attribute_i_j { name is \"$relation_key_attribute_i_j\"; type = string; };\n";
	}

	my $relation_num_foreign_key_attributes_i = $settings{"BCPD_relation_num_foreign_key_attributes_$i"};
	for ($j = 1; $j <= $relation_num_foreign_key_attributes_i; $j++)
	{
	  my $relation_foreign_key_attribute_i_j = $settings{"BCPD_relation_foreign_key_attribute_${i}_$j"};
	  my $relation_foreign_key_type_attribute_i_j = $settings{"BCPD_relation_foreign_key_type_attribute_${i}_$j"};
	  my $foreign_relation = $settings{"BCPD_relation_$relation_foreign_key_type_attribute_i_j"};

	  print DSC_FILE "fattribute $relation_foreign_key_attribute_i_j { name is \"$relation_foreign_key_attribute_i_j\"; type = $foreign_relation; };\n";

	  $join_from_relation[$join_counter] = $relation_i;
	  $join_to_relation[$join_counter] = $foreign_relation;
	  $join_from_key[$join_counter] = $relation_foreign_key_attribute_i_j;
	  $join_to_key[$join_counter] = $settings{"BCPD_relation_key_attribute_${relation_foreign_key_type_attribute_i_j}_1"};
	  $join_name[$join_counter] = "$join_from_relation[$join_counter]_$join_to_relation[$join_counter]";
	  $join_counter++;
	}

	my $relation_num_attributes_i = $settings{"BCPD_relation_num_attributes_$i"};
	for ($j = 1; $j <= $relation_num_attributes_i; $j++)
	{
	  my $relation_attribute_i_j = $settings{"BCPD_relation_attribute_${i}_$j"};
	  my $relation_type_attributes_i_j = $settings{"BCPD_relation_type_attributes_${i}_$j"};
	  my $relation_enum_attributes_i_j = $settings{"BCPD_relation_enum_attributes_${i}_$j"};
	  my $relation_attribute_additional_info_i_j = $settings{"BCPD_relation_attribute_additional_info_${i}_$j"};

	  print DSC_FILE "pattribute $relation_attribute_i_j { name is \"$relation_attribute_i_j\"; type = ";

	  if ($relation_type_attributes_i_j eq "continuous")
	  {
		 print DSC_FILE "continuous; ";
	  }
	  elsif ($relation_type_attributes_i_j eq "int")
	  {
		 my @indexes = split(/\,/, $relation_enum_attributes_i_j);
		 my $num = $indexes[1] - $indexes[0] + 1;

		 print DSC_FILE "discrete[$num] { \"$indexes[0]\"";

		 for (my $k = $indexes[0] + 1; $k <= $indexes[1]; $k++)
		 {
			print DSC_FILE ", \"$k\""; 
		 }

		 print DSC_FILE " }; ";
	  }
	  elsif ($relation_type_attributes_i_j =~ /char/)
	  {
		my @indexes = split(/\,/, $relation_enum_attributes_i_j);
		my $num = @indexes;

		print DSC_FILE "discrete[$num] { \"$indexes[0]\"";

		my $k;
		for ($k = 1; $k < $num; $k++)
		{
		  print DSC_FILE ", \"$indexes[$k]\"";
		}

		print DSC_FILE " }; ";
	  }

	  print DSC_FILE "$relation_attribute_additional_info_i_j };\n";
	}

	print DSC_FILE "}\n\n";
  }
}

sub print_joins
{
  my $i;

  for ($i = 0; $i < $join_counter; $i++)
  {
	my $short_from = substr($join_from_relation[$i], 0, 3);
	my $short_to = substr($join_to_relation[$i], 0, 3);
	
	print DSC_FILE "join $join_name[$i]\n";
	print DSC_FILE "{from $join_from_relation[$i] $short_from, \n";
	print DSC_FILE "$join_to_relation[$i] $short_to\n";
	print DSC_FILE "where $short_from.$join_from_key[$i] = $short_to.$join_to_key[$i] }\n\n";
  }
}


sub print_probs
{
  my $num_relations = $settings{"BCPD_num_relations"};
  my $i;
  my $j;

  for ($i = 1; $i <= $num_relations; $i++)
  {
	my $relation_i = $settings{"BCPD_relation_$i"};

	my $num_prob_attributes = $settings{"BCPD_relation_prob_attributes_$i"};

	for ($j = 1; $j <= $num_prob_attributes; $j++)
	{
	  my $prob_attribute = $settings{"BCPD_relation_prob_attribute_${i}_$j"};

	  my @parents = split(/\,/, $settings{"BCPD_relation_prob_attribute_parents_${i}_$j"});
	  my $num_parents = @parents;

	  print DSC_FILE "attrprobability(";
	  print DSC_FILE "$relation_i.$prob_attribute";

	  if ($num_parents > 0)
	  {
		print DSC_FILE " | ";

		print DSC_FILE "$relation_i.$parents[0]";
		
		my $p;
		for ($p = 1; $p < $num_parents; $p++)
		{
		  print DSC_FILE ",$relation_i.$parents[$p]";
		}
	  }

	  print DSC_FILE ")\n";
	  print DSC_FILE "{\n";

	  my $cpd_type = $settings{"BCPD_relation_prob_attribute_cpd_type_${i}_$j"};
	  my @cpd_dsc = split(/\|/, $settings{"BCPD_relation_prob_attribute_cpd_type_dsc_${i}_$j"});

	  my $fixed_cpd;
	  if ($settings{"BCPD_relation_prob_attribute_cpd_fixed_${i}_$j"} eq "true") { $fixed_cpd = "fixed"; } else { $fixed_cpd = ""; }

	  if ($cpd_type eq "discrete")
	  {
		my $p;
		for ($p = 0; $p < @cpd_dsc; $p++)
		{
		  print DSC_FILE "   $cpd_dsc[$p]\n";
		}
	  }
	  elsif ($cpd_type eq "nonlinear")
	  {	
		print DSC_FILE "(0) = nonlin { type = \"linear\"; };\n";
		print DSC_FILE "(1) = nonlin { type = \"$cpd_dsc[0]\"; params = \"$cpd_dsc[1]\"; };\n";
	  }

 	  print DSC_FILE "} $fixed_cpd\n\n";
 	}
  }
}

print_prm_header;
print_relations;
print_joins;
print_probs;

