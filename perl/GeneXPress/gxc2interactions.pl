#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $NO_STATUS = 0;
my $INSIDE_CLUSTER_STATUS = 1;
my $INSIDE_ATTRIBUTES_STATUS = 2;
my $INSIDE_ORF_STATUS= 3;

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub gx2interactions
{
  my ($gxc_file) = @_;

  my $status = $NO_STATUS;
  my %all_genes;

  open(GXC_FILE, "<$gxc_file");
  while(<GXC_FILE>)
  {
    chop;

    if (length($_) == 0) { $status = $NO_STATUS; %all_genes = (); }
    elsif ($_ =~ /Cluster[\s]([0-9]+)/) { $status = $INSIDE_CLUSTER_STATUS; }
    elsif ($_ =~ /=========/ && $status == $INSIDE_CLUSTER_STATUS) { $status = $INSIDE_ATTRIBUTES_STATUS; }
    elsif ($_ =~ /=========/ && $status == $INSIDE_ATTRIBUTES_STATUS) { $status = $INSIDE_ORF_STATUS; }

    if ($status == $INSIDE_ORF_STATUS && $_ !~ /=========/)
    {
      my @row = split(/\t/);

      foreach my $key (keys %all_genes)
      {
	print "$key\t$row[0]\n";
      }

      $all_genes{$row[0]} = "1";
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  gx2interactions($ARGV[0]);
}
else
{
  print "Usage: gx2interactions.pl genexpress_cluster_file\n\n";
}

1
