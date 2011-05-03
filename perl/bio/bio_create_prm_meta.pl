#! /usr/bin/perl

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# input: 
#    BCPM_prefix = the prefix of all files
#    BCPM_dir = the directory of the meta file
#    BCPM_<ALL_ATTRIBUTES_THAT_YOU_WANT_TO_CONTROL>
#
#    BCPM_gene_table - the gene table we use
#    BCPM_experiment_table - the experiment table we use
#    BCPM_expression_table - the expression table we use
#
#    BCPM_num_group_rvs - the number of group rvs we create
#    BCPM_num_rvs_in_group_i - the number of group rvs in the i-th group rv
#    BCPM_rel_in_rv_group_i - the name of the relation of the i-th group rv
#    BCPM_attr_in_rv_group_i_j - the name of the j-th attribute of the i-th group rv
#
#    BCPM_num_learn_phases - the number of learning phases (this is just for bio_create_prm_meta.pl -- this is total num phases as opposed to the number of phases for each attribute
#    BCPM_phase_prefix_i - a prefix to be added to all attributes of the i-th learning phase (should be "RelationName.AttrName")
#    BCPM_phase_num_phases_i - the number of learning phase for this prefix
#    BCPM_NumRvsInLearnPhase_i - number of rvs in the i-th learning phase
#    BCPM_LookaheadPhaseInLearnPhase_i - the number of lookahead steps to do for the attributes in the learning phase
#    BCPM_NumStepsInLearnPhase_i - the number of steps after which in the learning we go to the next learning phase
#    BCPM_NumForceStepsInLearnPhase_i - the number of force steps that we take (even if the score hurts us for instance)
#    BCPM_RelInLearnPhase_i_j - the relation for the j-th attribute in the i-th learning phase
#    BCPM_AttrInLearnPhase_i_j - the attribute name for the j-th attribute in the i-th learning phase
#
#    BCPM_num_score_nodes - the number of nodes that we output a score for during inference and learning
#    BCPM_hide_score_nodes - if true then we create the score nodes but hide them (this is necessary in learning for experiment groups)
#    BCPM_score_rel_i - the relation of the i-th node to score
#    BCPM_score_i - the attribute of the i-th node to score
#
#    BCPM_GeneXPress_num_nodes - the total number of nodes to pass to GeneXPress to print
#    BCPM_GeneXPress_outfile - the name of the xml file to write out
#    BCPM_GeneXPress_rel_i - the relation of the i-th attribute to handle in the GeneXPress files
#    BCPM_GeneXPress_attr_i - the attribute of the i-th attribute to handle in the GeneXPress files
#    BCPM_GeneXPress_print_i - the action to take for this attribute: currently support 'tree' (prints hierarchy) or 'naive_bayes' (prints probs)
#    BCPM_GeneXPressModule_num_nodes - the total number of module attributes
#    BCPM_GeneXPressModule_rel_i - the relation of the i-th module attribute
#    BCPM_GeneXPressModule_attr_i - the attribute of the i-th module attribute
#    BCPM_GeneXPressAttribute_num_groups - the total number of attribute groups
#    BCPM_GeneXPressAttributeGroup_rel_i - the relation of the i-th module attribute
#    BCPM_GeneXPressAttributeGroup_type_i - the type (currently 'Genes' or 'Experiments') of the i-th attribute group
#    BCPM_GeneXPressAttributeGroup_rep_i - the representation (currently 'Sparse' or 'Full') of the i-th attribute group
#    BCPM_GeneXPressAttributeGroup_dictionary_i - the name of the dictionary file to use for this relation
#    BCPM_GeneXPressAttributeGroup_link_i - a link that will be added to each attribute from this group where the ID of the object will be appended to the link
#
#    BCPM_bio - the name of the bio file to use (can be empty)
#    BCPM_fasta_file - currently we use one fasta file for all
#    BCPM_mapping_file - currently we use one fasta file for all
#    BCPM_upstream_length - how much to look in the sequences
#    BCPM_use_both_strands - whether to search on both strands
#    BCPM_pssm_length - the length of the PSSM to search for
#    BCPM_seed_length - the initial length of the seeds that are created
#    BCPM_projection_dist - the projection distance to use
#    BCPM_projection_num - the projection num to use
#    BCPM_num_test_seeds - the number of initial test seeds to use
#    BCPM_num_motif_variables - total number of motif variables that we have
#    BCPM_motif_variable_i - the name of the i-th motif variable
#    BCPM_motif_table_i - the name of the table for the i-th motif variable
#    BCPM_motif_target_variable_i - the name of the i-th target motif variable (basically, the expression level attribute)
#    BCPM_motif_target_table_i - the name of the target table for the i-th motif variable
#    BCPM_motif_file_i - the name of the output file for the i-th motif variable
#
#    BCPM_constraints_file - a file containing constraints for learning -- appended to the meta file while changing 'gene_table' and all other tables to the right ones
#
# output:
#    creates the meta file
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";

my %settings = load_settings($ARGV[0]);

my $prefix = $settings{"BCPM_prefix"};
my $dir = $settings{"BCPM_dir"};
my $num_group_rvs = $settings{"BCPM_num_group_rvs"};
my $num_learn_phase = $settings{"BCPM_num_learn_phases"};
my $num_score_nodes = $settings{"BCPM_num_score_nodes"};

my $r = int(rand 1000000000);

#--------------------
# get_attribute_value
#--------------------
sub get_attribute_value
{
  my $attribute_name = $_[0];
  my $default = $_[1];

  if (length($settings{"BCPM_$attribute_name"}) > 0)
  {
	 return "$attribute_name=" . $settings{"BCPM_$attribute_name"} . "\n";
  }
  else
  {
	 return "$attribute_name=" . $default . "\n";
  }
}

#--------------------
# get_settings_value
#--------------------
sub get_settings_value
{
  my $attribute_name = $_[0];
  my $default = $_[1];

  if (length($settings{"BCPM_$attribute_name"}) > 0) { return $settings{"BCPM_$attribute_name"}; }
  else { return $default; }
}

my $output_file = $dir . "/" . $prefix . "_0.meta"; 
open(OUT_META, ">$output_file") or die "could not open $output_file";

print OUT_META "prm=${prefix}_0.dsc\n";
print OUT_META "data=${prefix}_0.meta\n";
print OUT_META "estimation=${prefix}_0.meta\n";
print OUT_META "search=${prefix}_0.meta\n";
print OUT_META "output=out/${prefix}_0.out\n";
print OUT_META "#network=${prefix}_0.tree.dsc\n";
if (length($settings{"BCPM_bio"}) > 0) { print OUT_META "#bio=" . $settings{"BCPM_bio"} . "\n"; }
print OUT_META "\n";

print OUT_META "# DATABASE SETTINGS\n";
print OUT_META "dbms=mysql\n";
print OUT_META get_attribute_value("db", "");
print OUT_META "host=localhost\n";
print OUT_META get_attribute_value("ignore_null", "false");
print OUT_META "\n";

print OUT_META "# SEARCH SETTINGS\n";
print OUT_META get_attribute_value("max_steps", "10000");
print OUT_META get_attribute_value("max_flat_steps", "5");
print OUT_META get_attribute_value("flat_step_delta", "5");
print OUT_META get_attribute_value("max_restarts", "0");
print OUT_META get_attribute_value("max_parents", "23");
print OUT_META get_attribute_value("search_method", "hill_climb");
#print OUT_META get_attribute_value("search_method", "random_ascent");
print OUT_META get_attribute_value("random_step_prob", "0.9");
print OUT_META get_attribute_value("random_step_rate", "0.98");
print OUT_META get_attribute_value("steps_file", "${prefix}_0.steps");

print OUT_META get_attribute_value("use_refine_steps", "false");
print OUT_META get_attribute_value("use_fk_partitioning", "FALSE");
print OUT_META get_attribute_value("num_expansions", "0");
print OUT_META get_attribute_value("start_at_expansion", "2");
print OUT_META get_attribute_value("none_to_disc_scoring_method", "bde");
print OUT_META get_attribute_value("disc_to_disc_scoring_method", "bde");
print OUT_META get_attribute_value("force_incomplete_data", "false");
print OUT_META "\n";

print OUT_META "# MEASURE SETTINGS\n";
print OUT_META get_attribute_value("CompletionMeasure", "PrmLoopyInference");
print OUT_META get_attribute_value("LoopyPropType", "SimultaneousProp");
print OUT_META get_attribute_value("LoopyInferenceType", "Memory");
print OUT_META get_attribute_value("LoopyNumIterations", "20");
print OUT_META get_attribute_value("LoopyOperationType", "MaximumMarginals");
print OUT_META get_attribute_value("equiv_sample_size", "0.1");
print OUT_META get_attribute_value("normal_wishart_equiv_sample_size", "0.1");
print OUT_META get_attribute_value("normal_wishart_mean", "0");
print OUT_META get_attribute_value("normal_wishart_alpha", "1");
print OUT_META get_attribute_value("normal_wishart_precision", "1");
print OUT_META get_attribute_value("structure_prior_kappa", "0.9");
print OUT_META get_attribute_value("learn_tree_cpds", "true");
print OUT_META "\n";

print OUT_META get_attribute_value("learn_tree_cpds_independent", "false");
print OUT_META get_attribute_value("independent_tree_search", "beam_search");
print OUT_META get_attribute_value("learn_tree_with_shallow_key", "true");
print OUT_META get_attribute_value("consider_splits_separately", "false");
print OUT_META get_attribute_value("beam_size", "1");
print OUT_META get_attribute_value("search_lookahead", "1");
print OUT_META get_attribute_value("max_estimators_for_lookahead", "1");
print OUT_META get_attribute_value("max_lookahead_steps", "100000");
print OUT_META get_attribute_value("max_lookahead_flat_steps", "10");
print OUT_META get_attribute_value("lookahead_flat_step_delta", "5");
print OUT_META "\n";

print OUT_META get_attribute_value("em_iter_files", "em_iter");
print OUT_META get_attribute_value("max_em_iterations", "5");
print OUT_META get_attribute_value("random_init", "false");
print OUT_META "\n";

print OUT_META get_attribute_value("MaxCacheSize", "100000");
print OUT_META "\n";

print OUT_META get_attribute_value("use_sparse_parents", "false");
print OUT_META get_attribute_value("num_sparse_parents", "1");
print OUT_META get_attribute_value("num_steps_to_recompute_sparse_parents", "1");
print OUT_META get_attribute_value("recompute_sparse_parents_upon_phase_change", "false");
print OUT_META "\n";

#----------------------------------------------------------------------------------------
# Group Rvs
#----------------------------------------------------------------------------------------
if ($num_group_rvs > 0)
{
  print OUT_META get_attribute_value("NumGroupRvs", "$num_group_rvs");
  for (my $i = 1; $i <= $num_group_rvs; $i++)
  {
    my $num_rvs_in_group_i = $settings{"BCPM_num_rvs_in_group_$i"};
    print OUT_META get_attribute_value("NumRvsInGroup_$i", "$num_rvs_in_group_i");

    my $rel_in_rv_group_i = $settings{"BCPM_rel_in_rv_group_$i"};
    print OUT_META get_attribute_value("RelInRvGroup_$i", "$rel_in_rv_group_i");

    for (my $j = 1; $j <= $num_rvs_in_group_i; $j++)
    {
      my $attr_in_rv_group_i_j = $settings{"BCPM_attr_in_rv_group_${i}_$j"};
      print OUT_META get_attribute_value("AttrInRvGroup_${i}_$j", "$attr_in_rv_group_i_j");
    }
  }
  print OUT_META "\n\n";
}

#----------------------------------------------------------------------------------------
# Scoring Nodes
#----------------------------------------------------------------------------------------
if ($num_score_nodes > 0)
{
  my $hide_score_nodes = $settings{"BCPM_hide_score_nodes"};

  if ($hide_score_nodes eq "true") { print OUT_META "#num_score_nodes=$num_score_nodes\n"; }
  else { print OUT_META "num_score_nodes=$num_score_nodes\n"; }

  for (my $i = 1; $i <= $num_score_nodes; $i++)
  {
	 print OUT_META "score_rel_$i=" . $settings{"BCPM_score_rel_$i"} . "\n";
	 print OUT_META "score_$i=" . $settings{"BCPM_score_$i"} . "\n";
  }
  print OUT_META "\n";
}

#----------------------------------------------------------------------------------------
# LearnPhases
#----------------------------------------------------------------------------------------
if ($num_learn_phase > 0)
{
  for (my $k = 1; $k <= $num_learn_phase;)
  {
    my $phase_prefix = $settings{"BCPM_phase_prefix_$k"};
    my $num_phases_for_attr = $settings{"BCPM_phase_num_phases_$k"};

    print OUT_META "${phase_prefix}_NumLearnPhases=" . $settings{"BCPM_phase_num_phases_$k"} . "\n";

    for (my $i = 1; $i <= $num_phases_for_attr; $i++)
    {
      print OUT_META "${phase_prefix}_LookaheadPhaseInLearnPhase_$i=" . $settings{"BCPM_LookaheadPhaseInLearnPhase_$k"} . "\n";
      print OUT_META "${phase_prefix}_NumStepsInLearnPhase_$i=" . $settings{"BCPM_NumStepsInLearnPhase_$k"} . "\n";
      print OUT_META "${phase_prefix}_NumForceStepsInLearnPhase_$i=" . $settings{"BCPM_NumForceStepsInLearnPhase_$k"} . "\n";

      my $num_rvs_in_learn_phase = $settings{"BCPM_NumRvsInLearnPhase_$k"};
      print OUT_META "${phase_prefix}_NumRvsInLearnPhase_$i=$num_rvs_in_learn_phase\n";

      for (my $j = 1; $j <= $num_rvs_in_learn_phase; $j++)
      {
	print OUT_META "${phase_prefix}_RelInLearnPhase_${i}_$j=" . $settings{"BCPM_RelInLearnPhase_${k}_$j"} . "\n";
	print OUT_META "${phase_prefix}_AttrInLearnPhase_${i}_$j=" . $settings{"BCPM_AttrInLearnPhase_${k}_$j"} . "\n";
      }
      print OUT_META "\n";

      $k++;
    }
    print OUT_META "\n";
  }
}

#----------------------------------------------------------------------------------------
# GeneXPress attributes
#----------------------------------------------------------------------------------------
my $GeneXPress_num_nodes = $settings{"BCPM_GeneXPress_num_nodes"};
if ($GeneXPress_num_nodes > 0)
{
  my $GeneXPress_outfile = $settings{"BCPM_GeneXPress_outfile"};

  print OUT_META "GeneXPress_num_nodes=$GeneXPress_num_nodes\n";
  print OUT_META "GeneXPress_outfile=$GeneXPress_outfile\n";

  for (my $i = 1; $i <= $GeneXPress_num_nodes; $i++)
  {
	 print OUT_META "GeneXPress_rel_$i=" . $settings{"BCPM_GeneXPress_rel_$i"} . "\n";
	 print OUT_META "GeneXPress_attr_$i=" . $settings{"BCPM_GeneXPress_attr_$i"} . "\n";
	 print OUT_META "GeneXPress_print_$i=" . $settings{"BCPM_GeneXPress_print_$i"} . "\n";
  }
  print OUT_META "\n";

  my $GeneXPressModule_num_nodes = $settings{"BCPM_GeneXPressModule_num_nodes"};
  if ($GeneXPressModule_num_nodes > 0)
  {
	 print OUT_META "GeneXPressModule_num_nodes=$GeneXPressModule_num_nodes\n";

	 for (my $i = 1; $i <= $GeneXPressModule_num_nodes; $i++)
	 {
		print OUT_META "GeneXPressModule_rel_$i=" . $settings{"BCPM_GeneXPressModule_rel_$i"} . "\n";
		print OUT_META "GeneXPressModule_attr_$i=" . $settings{"BCPM_GeneXPressModule_attr_$i"} . "\n";
	 }
  }
  print OUT_META "\n";

  my $GeneXPressAttributeGroup_num_groups = $settings{"BCPM_GeneXPressAttribute_num_groups"};
  if ($GeneXPressAttributeGroup_num_groups > 0)
  {
	 print OUT_META "GeneXPressAttribute_num_groups=$GeneXPressAttributeGroup_num_groups\n";

	 for (my $i = 1; $i <= $GeneXPressAttributeGroup_num_groups; $i++)
	 {
		print OUT_META "GeneXPressAttributeGroup_rel_$i=" . $settings{"BCPM_GeneXPressAttributeGroup_rel_$i"} . "\n";
		print OUT_META "GeneXPressAttributeGroup_type_$i=" . $settings{"BCPM_GeneXPressAttributeGroup_type_$i"} . "\n";
		print OUT_META "GeneXPressAttributeGroup_rep_$i=" . $settings{"BCPM_GeneXPressAttributeGroup_rep_$i"} . "\n";
		print OUT_META "GeneXPressAttributeGroup_dictionary_$i=" . $settings{"BCPM_GeneXPressAttributeGroup_dictionary_$i"} . "\n";
		print OUT_META "GeneXPressAttributeGroup_link_$i=" . $settings{"BCPM_GeneXPressAttributeGroup_link_$i"} . "\n";
	 }
  }
  print OUT_META "\n\n";
}

#----------------------------------------------------------------------------------------
# MOTIF VARIABLES
#----------------------------------------------------------------------------------------
if (length($settings{"BCPM_bio"}) > 0)
{
  open(BIO_XML_FILE, ">$dir/" . $settings{"BCPM_bio"});

  my $fasta_file = get_settings_value("fasta_file", "");
  my $mapping_file = $settings{"BCPM_mapping_file"};
  my $upstream_length = get_settings_value("upstream_length", "1000");
  my $use_both_strands = get_settings_value("use_both_strands", "true");
  my $pssm_length = get_settings_value("pssm_length", "15");
  my $seed_length = get_settings_value("seed_length", "6");

  print BIO_XML_FILE "<BioObjects>\n";

  print BIO_XML_FILE "  <PSSMS>\n";

  my $num_motif_variables = $settings{"BCPM_num_motif_variables"};
  for (my $i = 1; $i <= $num_motif_variables; $i++)
  {
	 my $attribute = $settings{"BCPM_motif_variable_$i"};
	 my $relation = $settings{"BCPM_motif_table_$i"};
	 my $target_attribute = $settings{"BCPM_motif_target_variable_$i"};
	 my $target_relation = $settings{"BCPM_motif_target_table_$i"};
	 my $motif_file = $settings{"BCPM_motif_file_$i"};
    my $projection_dist = $settings{"BCPM_projection_dist"};
    my $projection_num = $settings{"BCPM_projection_num"};
    my $num_test_seeds = $settings{"BCPM_num_test_seeds"};

	 print BIO_XML_FILE "    <PSSM Relation=\"$relation\" ";
	 print BIO_XML_FILE "Attribute=\"$attribute\" ";
	 print BIO_XML_FILE "TargetRelation=\"$target_relation\" ";
	 print BIO_XML_FILE "TargetAttribute=\"$target_attribute\" ";
	 print BIO_XML_FILE "File=\"$motif_file\" ";
	 print BIO_XML_FILE "MappingFile=\"$mapping_file\">\n";

	 print BIO_XML_FILE "      <Weights>\n";
	 print BIO_XML_FILE "      </Weights>\n";

	 print BIO_XML_FILE "      <Learn ";
	 print BIO_XML_FILE "Fasta=\"$fasta_file\" ";
	 print BIO_XML_FILE "UpstreamLength=\"$upstream_length\" ";
	 print BIO_XML_FILE "SeedLength=\"$seed_length\" ";
	 print BIO_XML_FILE "LearnLength=\"$pssm_length\" ";
	 print BIO_XML_FILE "UseBothStrands=\"$use_both_strands\" ";
	 print BIO_XML_FILE "ProjectionDist=\"$projection_dist\" ";
	 print BIO_XML_FILE "ProjectionNum=\"$projection_num\" ";
	 print BIO_XML_FILE "NumTestSeeds=\"$num_test_seeds\" ";
	 print BIO_XML_FILE " >\n";
	 print BIO_XML_FILE "      </Learn>\n";

	 print BIO_XML_FILE "      <Inference InferenceType=\"Loopy\">\n";
	 print BIO_XML_FILE "      </Inference>\n";

	 print BIO_XML_FILE "    </PSSM>\n";
  }

  print BIO_XML_FILE "  </PSSMS>\n";

  print BIO_XML_FILE "</BioObjects>\n";
}

#----------------------------------------------------------------------------------------------
# ADDING CONSTRAINTS
#----------------------------------------------------------------------------------------------
if (length($settings{"BCPM_constraints_file"}) > 0)
{
  my $constraints_file = $settings{"BCPM_constraints_file"};

  my $gene_table = $settings{"BCPM_gene_table"};
  my $experiment_table = $settings{"BCPM_experiment_table"};
  my $expression_table = $settings{"BCPM_expression_table"};

  change_attribute_in_file("$constraints_file", "tmp.$r", "gene_table", "$gene_table");
  change_attribute_in_file("tmp.$r", "tmp.$r", "experiment_table", "$experiment_table");
  change_attribute_in_file("tmp.$r", "tmp.$r", "expression_table", "$expression_table");

  open(CONSTRAINTS_FILE, "<tmp.$r");
  while(<CONSTRAINTS_FILE>) { print OUT_META "$_"; }

  delete_file("tmp.$r");
}
