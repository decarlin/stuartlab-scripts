#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/file.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $groups_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $color_scheme_name = get_arg("n", "MyColorScheme", \%args);
my $min_num_groups = get_arg("g", 1, \%args);
my $min_weights_file = get_arg("f", "", \%args);

my @groups;
my %groups2groupid;
my $groups_counter = 0;
open(GROUPS_FILE, "<$groups_file") or die "could not open $groups_file";
while(<GROUPS_FILE>)
{
  chop;

  my @row = split(/\t/);

  my $group_id = $groups2groupid{$row[1]};
  if (length($group_id) == 0)
  {
    $group_id = $groups_counter++;
    $groups2groupid{$row[1]} = $group_id;
  }

  $groups[$group_id] .= "$row[0]\t";
}

my %groups2minweights;
if (length($min_weights_file) > 0)
{
  open(MIN_WEIGHTS_FILE, "<$min_weights_file");
  while(<MIN_WEIGHTS_FILE>)
  {
    chop;

    my @row = split(/\t/);

    $groups2minweights{$groups2groupid{$row[0]}} = $row[1];
  }
}

print "<GeneXPressColorSchemes>\n";
print "  <ColorScheme Name=\"$color_scheme_name\" MinGroups=\"$min_num_groups\" ObjectsType=\"Experiments\">\n";

for (my $i = 0; $i < @groups; $i++)
{
  my @row = split(/\t/, $groups[$i]);

  print "    <ColorAssignment Color=\"255,0,0,1\" ";

  if (length($groups2minweights{$i}) > 0) { print "MinWeight=\"$groups2minweights{$i}\" "; }

  print "Objects=\"";

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i > 0) { print ";"; }
    print "$row[$i]";
  }

  print "\">\n";
  print "    </ColorAssignment>\n";
}

print "  </ColorScheme>\n";
print "</GeneXPressColorSchemes>\n";

__DATA__

create_genexpress_experiment_groups.pl <experiment groups file>

   Creates experiment groups (currently as color schemes) from a tab delimited file
   (experiment name<tab>group name)
   that lists for each experiment, the group to which it belongs

   -n <name>:   The name of the color scheme

   -g <num>:    The minimum number of experiment groups

   -f <file>:   Minimum weights file. If supplied, this is a tab delimited file
                that lists for each experiment group, its minimum weight.

