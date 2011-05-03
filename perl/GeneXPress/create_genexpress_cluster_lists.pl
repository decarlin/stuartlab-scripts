#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/bio_execute.pl";
require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $cgcs_null_value = "CGCL___NULL___CGCL";

my $r = int(rand(10000000));

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub create_genexpress_cluster_list
{
 my ($genexpress_file, $attribute, $add_modules_to_file, $name) = @_;

  open(GENEXPRESS_FILE, "<$genexpress_file") or die "Could not open genexpress file $genexpress_file\n";

  my @cluster_stack;
  my @cluster_attribute_stack;
  my $cluster_size = 0;;
  my @clusters;
  my $counter = 0;

  while(<GENEXPRESS_FILE>)
  {
    chop;

    if (/[\<]Root/ || /[\<]Child/)
    {
      /ClusterNum=[\"]([0-9]+)[\"]/;

      $cluster_stack[$cluster_size] = $1;

      /SplitAttribute=[\"]([^\s]+)[\"]/;

      $cluster_attribute_stack[$cluster_size] = $1;

      #print "Pushing $cluster_stack[$cluster_size] attribute is $cluster_attribute_stack[$cluster_size]\n";

      if ($cluster_size > 0 && $cluster_attribute_stack[$cluster_size - 1] eq $attribute && $cluster_attribute_stack[$cluster_size] ne $attribute)
      {
	$clusters[$counter++] = $cluster_stack[$cluster_size];
      }

      $cluster_size++;
    }

    if (/[\<][\/]Root[\>]/ || /[\<][\/]Child[\>]/)
    {
      $cluster_size--;
    }
  }

  @clusters = sort { $a <=> $b } @clusters;

  my $cluster_list_str = "";
  for (my $i = 0; $i < $counter; $i++)
  {
    if ($i == 0) { $cluster_list_str .= "$clusters[$i]"; }
    else { $cluster_list_str .= " $clusters[$i]"; }
  }

  if ($add_modules_to_file eq "1")
  {
    open(GENEXPRESS_FILE, "<$genexpress_file") or die "Could not open genexpress file $genexpress_file\n";
    open(OUT_GENEXPRESS_FILE, ">$genexpress_file.$r");
    while(<GENEXPRESS_FILE>)
    {
      chop;

      if ($_ !~ /<[\/]GeneXPress>/ && $_ !~ /<[\/]TSC>/)
      {
	print OUT_GENEXPRESS_FILE "$_\n";
      }
      else
      {
	print OUT_GENEXPRESS_FILE "<GeneXPressClusterLists>\n";
	print OUT_GENEXPRESS_FILE "  <ClusterList Name=\"$name\" List=\"$cluster_list_str\">\n";

	print OUT_GENEXPRESS_FILE "  </ClusterList>\n";
	print OUT_GENEXPRESS_FILE "</GeneXPressClusterLists>\n";
      }
    }
    print OUT_GENEXPRESS_FILE "</GeneXPress>\n";
    close(OUT_GENEXPRESS_FILE);
    system("mv $genexpress_file.$r $genexpress_file");
  }
  else
  {
    print "<GeneXPressClusterLists>\n";
    print "  <ClusterList Name=\"$name\" List=\"$cluster_list_str\">\n";

    print "  </ClusterList>\n";
    print "</GeneXPressClusterLists>\n";
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  create_genexpress_cluster_list($ARGV[0],
				 get_arg("a", "g_cluster", \%args),
				 get_arg("Add", 0, \%args),
				 get_arg("n", "Modules", \%args));
}
else
{
  print "Usage: create_genexpress_cluster_lists.pl genexpress_file\n\n";
  print "      -a  <attribute>:     The name of the attribute that will be used to define the cluster list (default is g_cluster)\n";
  print "      -n  <name>:          The name that will be assigned to this cluster list (default is Modules)\n";
  print "      -Add:                Add the clusters lists produced to the genexpress file\n";
}

1
