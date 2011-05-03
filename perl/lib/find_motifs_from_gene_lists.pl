#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/bio_get_file_names_for_dir.pl";

my $fmfgl_null = "FMFGL____NULL___FMFGL";

#--------------------------------------------------------------------------------
# find_motifs_in_file
#--------------------------------------------------------------------------------
sub find_motifs_in_file
{
  my ($file_name, $output_dir, $program, $initial_concensus, $upstream_length, $sequence_file, $use_one_strand) = @_;

  open(MEME_FILE, ">$output_dir/$file_name.fmc.in");
  copy_file($file_name, "$output_dir/");

  print MEME_FILE "program_1=$program\n";
  if ($program eq "MEME") { print MEME_FILE "program_exe_1=/u/jstuart/bin/meme\n"; }

  if ($initial_concensus ne $fmfgl_null) { print MEME_FILE "initial_concensus_1=$initial_concensus\n"; }

  print MEME_FILE "upstream_size_1=$upstream_length\n";

  print MEME_FILE "num_runs=1\n";
  print MEME_FILE "run_1=program_1,upstream_size_1";
  if ($initial_concensus ne $fmfgl_null) { print MEME_FILE ",initial_concensus_1\n"; } else { print MEME_FILE "\n"; }

  print MEME_FILE "upstream_sequence_file=$sequence_file\n";
  print MEME_FILE "porf_file=$file_name\n";
  if ($use_one_strand) { print MEME_FILE "use_both_strands=false\n"; } else { print MEME_FILE "use_both_strands=true\n"; }

  execute("cd $output_dir; $ENV{HOME}/develop/perl/find_motifs_in_cluster.pl $file_name.fmc.in; cd ..", 1);
}

#--------------------------------------------------------------------------------
# find_motifs_from_gene_lists
#--------------------------------------------------------------------------------
sub find_motifs_from_gene_lists
{
  my ($file_name, $dir_name, $output_dir, $program, $initial_concensus, $upstream_length, $sequence_file, $use_one_strand) = @_;

  if ($file_name ne $fmfgl_null)
  {
    find_motifs_in_file($file_name, $output_dir, $program, $initial_concensus, $upstream_length, $sequence_file, $use_one_strand);
  }
  elsif ($dir_name ne $fmfgl_null)
  {
    my @files = get_file_names_for_dir($dir_name);

    for (my $i = 0; $i < @files; $i++)
    {
      if ($files[$i] ne "." && $files[$i] ne "$dir_name/$output_dir")
      {
	$files[$i] =~ s/[\.][\/]//g;
	print "$files[$i]...\n";
	find_motifs_in_file($files[$i], $output_dir, $program, $initial_concensus, $upstream_length, $sequence_file, $use_one_strand);
      }
    }
  }
  else { print "You must specify a file or directory name\n"; }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  find_motifs_from_gene_lists (get_arg("f",    $fmfgl_null,                                         \%args),
			       get_arg("d",    $fmfgl_null,                                         \%args),
			       get_arg("o",    ".",                                                 \%args),
			       get_arg("p",    "MEME",                                              \%args),
			       get_arg("i",    $fmfgl_null,                                         \%args),
			       get_arg("u",    1000,                                                \%args),
			       get_arg("s",    "/u/erans/D/Biology/utils/data/yeast_promoters.fas", \%args),
			       get_arg("1str", 0,                                                   \%args));
}
else
{
  print "Usage: find_motifs_from_gene_lists.pl \n\n";
  print "      -f <file name>:         The file containing the gene list on which to search for motifs\n";
  print "      -d <directory>:         Use all files in this directory as gene lists\n";
  print "      -o <output directory>:  Temporary and output files will be written to this directory\n\n";
  print "      -p <program>:           The program to use for finding motifsDefault is MEME\n";
  print "      -i <pattern>:           The initial concensus sequence to use (default is none)\n";
  print "      -u <upstream size>:     The length of the upstream sequence to use (default is 1000)\n";
  print "      -s <sequence file>:     The sequence file of promoters to use (default /u/erans/D/Biology/utils/data/yeast_promoters.fas\n";
  print "      -1str:                  Use one strand in the search (default is using both strands)\n";
}

1
