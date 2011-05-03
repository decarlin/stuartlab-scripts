#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gx_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $delete_cluster_num = get_arg("n", -1, \%args);
my $delete_cluster_file = get_arg("f", "", \%args);

my %delete_clusters;
if ($delete_cluster_num != -1) { $delete_clusters{$delete_cluster_num} = "1"; }
else
{
  open(FILE, "<$delete_cluster_file");
  while(<FILE>)
  {
    chop;

    $delete_clusters{$_} = "1";
  }
}

open(GX_FILE, "<$gx_file") or die "Could not open $gx_file";
my $inside_delete_cluster = 0;
my $stack_level = 0;
while(<GX_FILE>)
{
  chop;

  if (/<Child[\s]ClusterNum=[\"]([0-9]+)[\"]/)
  {
    if ($delete_clusters{$1} eq "1")
    {
      if ($inside_delete_cluster == 0)
      {
	$inside_delete_cluster = 1;
	$stack_level = 0;

	s/NumChildren=[\"]2[\"]/NumChildren="0"/;

	print "$_\n";
      }
    }

    if ($inside_delete_cluster == 0) { print "$_\n"; }

    if ($inside_delete_cluster == 1) { $stack_level++; }
  }
  elsif (/<[\/]Child>/)
  {
    if ($inside_delete_cluster == 1)
    {
      $stack_level--;

      if ($stack_level == 0)
      {
	print "$_\n";
	$inside_delete_cluster = 0;
	$stack_level = 0;
      }
    }
    else { print "$_\n"; }
  }
  elsif ($inside_delete_cluster == 0)
  {
    print "$_\n";
  }
}

__DATA__

gxm2tab.pl <gx file>

   Deletes nodes from a gx file. For each of the specified nodes,
   it makes those nodes into leaves (thereby deleting their descendants)

   -n <num>:    Delete node with cluster num = num
   -f <file>:   Delete nodes with cluster nums that appear in the file

