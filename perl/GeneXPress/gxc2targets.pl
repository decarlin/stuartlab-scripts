#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/load_args.pl";

my $NO_STATUS = 0;
my $INSIDE_CLUSTER_STATUS = 1;
my $INSIDE_ATTRIBUTES_STATUS = 2;
my $INSIDE_ORF_STATUS= 3;

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub gx2targets
{
  my ($gxc_file, $attribute, $min_experiments, $max_depth) = @_;

  my $status = $NO_STATUS;
  my $print_orfs = 0;
  my %all_attributes;

  open(GXC_FILE, "<$gxc_file");
  while(<GXC_FILE>)
  {
    chop;

    if (length($_) == 0) { $status = $NO_STATUS; $print_orfs = 0; %all_attributes = (); }
    elsif ($_ =~ /Cluster[\s]([0-9]+)/) { $status = $INSIDE_CLUSTER_STATUS; }
    elsif ($_ =~ /=========/ && $status == $INSIDE_CLUSTER_STATUS) { $status = $INSIDE_ATTRIBUTES_STATUS; }
    elsif ($_ =~ /=========/ && $status == $INSIDE_ATTRIBUTES_STATUS) { $status = $INSIDE_ORF_STATUS; }

    if ($status == $INSIDE_ATTRIBUTES_STATUS && $_ !~ /=========/)
    {
      my @row = split(/\t/);

      if ($row[0] eq $attribute || $attribute eq "ALL")
      {
	if ($row[1] <= $max_depth && $row[2] >= $min_experiments)
	{
	  $print_orfs = 1;
	  $all_attributes{$row[0]} = "1";
	}
      }
    }
    elsif ($status == $INSIDE_ORF_STATUS && $print_orfs && $_ !~ /=========/)
    {
      my @row = split(/\t/);

      foreach my $key (keys %all_attributes)
      {
	print "$key\t$row[0]\n";
      }
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  gx2targets($ARGV[0],
	     get_arg("a", "ARG80", \%args),
	     get_arg("e", 0, \%args),
	     get_arg("d", 100, \%args));
}
else
{
  print "Usage: gx2targets.pl genexpress_cluster_file\n\n";
  print "      -a:   attribute to extract targets for (ALL for all attributes)\n";
  print "      -e:   minimum number of experiments for the attribute (default 0)\n";
  print "      -d:   maximum depth for the attribute (default 100)\n";
}

1
