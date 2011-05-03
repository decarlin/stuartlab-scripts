#!/usr/bin/perl

#----------------------------------------------------------------------------------------------------------
# input: 
#    prefix - the prefix of the files that we use
#
#    dir - the directory of the prm files
#
#    iteration - the iteration #
#
#    dataset_name - for analysis files that are printed out
#
#    gene_dsc_file - tab delimited: ORF, Gene name, Gene description
#    external_attributes_file - will be used by the genexpress utility
#
# output:
#----------------------------------------------------------------------------------------------------------

use strict;

require "$ENV{MYPERLDIR}/lib/bio_load_settings.pl";
require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/load_file_attribute_groups.pl";

my %settings = load_settings($ARGV[0]);

my $prefix = $settings{"prefix"};

my $dir = $settings{"dir"};

my $iteration;
if (length($ARGV[1]) > 0) { $iteration = $ARGV[1]; }
else { $iteration = $settings{"iteration"}; }
my $next_iteration = $iteration + 1;

my $tsc_file = "$dir/out/${prefix}_l$iteration.tsc";

my $verbose = 1;

my $external_attributes_file = $settings{"external_attributes_file"};
my $gene_dsc_file = $settings{"gene_description_file"};

#-----------------------------------------------------------------------------------------
# print_genexpress_analysis
#-----------------------------------------------------------------------------------------
sub print_genexpress_analysis
{
  my $stats_summary_file = "$dir/out/${prefix}_l$iteration";
  #execute("$ENV{HOME}/develop/perl/lib/genexpress_util.pl $tsc_file -A $external_attributes_file -gd $gene_dsc_file -o $stats_summary_file -Sc 2 -SS");

  my $three_tier_graph = "$dir/out/${prefix}_l$iteration.3tier";
  execute("$ENV{HOME}/develop/perl/lib/genexpress_util.pl $tsc_file -A $external_attributes_file -gd $gene_dsc_file -o $three_tier_graph -f TabDelimitedFormat -Sc 2 -3G", 1);

  my $bn_like_graph = "$dir/out/${prefix}_l$iteration.bn";
  #execute("$ENV{HOME}/develop/perl/lib/genexpress_util.pl $tsc_file -A $external_attributes_file -gd $gene_dsc_file -o $bn_like_graph -Sc 2 -BG");

  my $dataset = $settings{"dataset_name"};
  #execute("perl $ENV{HOME}/develop/perl/Analysis/report.pl $dataset $tsc_file $tsc_file", $verbose);
}

print_genexpress_analysis;

