#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/load_args.pl";

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub gx2gene_lists
{
  my ($gxc_file, $output_directory, $print_descriptions) = @_;

  my $inside_orfs = 0;
  my $cluster = 0;

  open(GXC_FILE, "<$gxc_file");
  while(<GXC_FILE>)
  {
    chop;

    if (length($_) == 0) { $inside_orfs = 0; }
    elsif ($_ =~ /=========/) { $inside_orfs = 1; }
    elsif ($_ =~ /Cluster[\s]([0-9]+)/) { $cluster = $1; open(OUTFILE, ">$output_directory/$cluster.tab"); }

    if ($inside_orfs && $_ !~ /=========/)
    {
      my @row = split(/\t/);

      print OUTFILE "$row[0]\t";

      if ($print_descriptions)
      {
	print OUTFILE "$row[1]\t";
      }

      print OUTFILE "\n";
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  gx2gene_lists($ARGV[0],
		$ARGV[1],
		get_arg("d", 0, \%args));
}
else
{
  print "Usage: gx2gene_lists.pl genexpress_cluster_file output_directory\n\n";
  print "      -d:     Print the description of the gene as well (by default only ORF is printed)\n";
}

1
