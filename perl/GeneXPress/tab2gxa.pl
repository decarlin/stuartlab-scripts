#! /usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

#---------------------------------------------------------------------------
# remove_illegal_chars
#---------------------------------------------------------------------------
sub remove_illegal_xml_chars
{
  my $str = $_[0];
  $str =~ s/\&/&amp;/g;
  $str =~ s/\"/&quot;/g;
  $str =~ s/\'/&apos;/g;
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
  return $str;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub fix_object_name
{
  my $str = $_[0];
#  $str =~ s/[\.]/_/g;
  return $str;
}

#--------------------------------------------------------------------------------
# print_matrix
#--------------------------------------------------------------------------------
sub to_gx_attributes
{
  my ($attributes_file, $objects_type, $object_type, $object_id, $attribute_threshold) = @_;

  my @columnid_to_attribute;
  my @rowid_to_object_id;
  my @object_assignments;
  my %attributes_domains;
  my %attributes_domains_cache;

  open(ATTRIBUTES_FILE, "<$attributes_file");
  my $line = <ATTRIBUTES_FILE>;
  chop $line;
  my @desc = split(/\t/, $line);
  my $num_columns = @desc;

  my @matrix;

  my $counter = 0;
  while(<ATTRIBUTES_FILE>)
  {
    chop;

    my @row = split(/\t/);
    for (my $i = 1; $i < @row; $i++)
    {
      $matrix[$counter][$i] = $row[$i];
    }

    $counter++;
  }

  # exclude columns from a predefined file
  open(EXCLUDE_ATTRIBUTES, "</u/erans/D/Biology/DATA/GO/exclude_annotations.dat");
  my %exclude_attributes;
  while(<EXCLUDE_ATTRIBUTES>)
  {
    chop;
    $exclude_attributes{$_} = "1";
  }

  # exclude columns that don't have enough diversity
  my %columns_passing_threshold;
  my %attribute_counts_str;
  my @attribute_counts;
  for (my $i = 1; $i < $num_columns; $i++)
  {
    my %value_to_index;
    my $num_values = 0;
    for (my $j = 0; $j < $counter; $j++)
    {
      my $value = $matrix[$j][$i];
      if (length($value_to_index{$value}) == 0)
      {
	$value_to_index{$value} = $num_values;
	$attribute_counts[$i][$num_values] = 1;
	$num_values++;
      }
      else
      {
	$attribute_counts[$i][$value_to_index{$value}]++;
      }
    }

    my $num_values_passing = 0;
    my $counts_str = "";
    for (my $j = 0; $j < $num_values; $j++)
    {
      if ($j == 0) { $counts_str .= "$attribute_counts[$i][$j]"; }
      else { $counts_str .= " $attribute_counts[$i][$j]"; }

      if ($attribute_counts[$i][$j] >= $attribute_threshold)
      {
	$num_values_passing++;
      }
    }

    if ($num_values_passing >= 2)
    {
      $columns_passing_threshold{$i} = "1";
      $attribute_counts_str{$i} = $counts_str;
    }
  }

  open(ATTRIBUTES_FILE, "<$attributes_file");

  my $line = <ATTRIBUTES_FILE>;
  chop $line;
  my @desc = split(/\t/, $line);
  for (my $i = 0; $i < @desc; $i++)
  {
    $columnid_to_attribute[$i] = $desc[$i];
  }

  my %object_assignments;
  my %rowid_to_object_id;
  my $counter = 0;
  while(<ATTRIBUTES_FILE>)
  {
    chop;

    my @row = split(/\t/);
    my $value_str = "";
    for (my $i = 1; $i < @row; $i++)
    {
      if ($columns_passing_threshold{$i} eq "1" && $exclude_attributes{$columnid_to_attribute[$i]} ne "1")
      {
	if ($i > 1) { $value_str .= ";"; }
	$value_str .= "$row[$i]";

	my $attribute = $columnid_to_attribute[$i];
	my $key = "${attribute}_$row[$i]";
	if ($attributes_domains_cache{$key} ne "1")
	{
	  $attributes_domains_cache{$key} = "1";
	  if (length($attributes_domains{$attribute}) == 0) { $attributes_domains{$attribute} = $row[$i]; }
	  else { $attributes_domains{$attribute} .= " $row[$i]"; }
	}
      }
    }

    $rowid_to_object_id[$counter] = $row[0];

    $object_assignments[$counter] = $value_str;

    $counter++;
  }

  print "<GeneXPress>\n";

  print "<GeneXPressAttributes>\n";
  print "  <Attributes Id=\"0\">\n";

  for (my $i = 1; $i < @columnid_to_attribute; $i++)
  {
    if ($columns_passing_threshold{$i} eq "1" && $exclude_attributes{$columnid_to_attribute[$i]} ne "1")
    {
      my $attribute = $columnid_to_attribute[$i];
      my $legal_attribute_name = remove_illegal_xml_chars($attribute);

      my $attribute_domain = $attributes_domains{$attribute};
      my $counts_str = $attribute_counts_str{$i};
      if ($attribute_domain eq "1 0")
      {
	$attribute_domain = "0 1";

	my @row = split(/\s/, $counts_str);
	$counts_str = "$row[1] $row[0]";
      }

      print "    <Attribute Name=\"$legal_attribute_name\" Id=\"$i\" Counts=\"$counts_str\" Value=\"$attribute_domain\" />\n";
    }
  }

  print "  </Attributes>\n";
  print "</GeneXPressAttributes>\n";

  print "<GeneXPressObjects>\n";
  print "  <Objects Type=\"$objects_type\">\n";

  for (my $i = 0; $i < @object_assignments; $i++)
  {
    my $fixed_object_id = fix_object_name($rowid_to_object_id[$i]);
    print "    <$object_type Id=\"$i\" $object_id=\"$fixed_object_id\">\n";
    print "      <Attributes AttributesGroupId=\"0\" Type=\"Full\" Value=\"$object_assignments[$i]\"/>\n";
    print "    </$object_type>\n";
  }

  print "  </Objects>\n";
  print "</GeneXPressObjects>\n";

  print "</GeneXPress>\n";
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  to_gx_attributes($ARGV[0],
		   get_arg("o", "Genes", \%args),
		   get_arg("ot", "Gene", \%args),
		   get_arg("oi", "ORF", \%args),
		   get_arg("t", 5, \%args));
}
else
{
  print "Usage: flat_file_to_gx_attributes.pl flat_file\n\n";
  print "      -o  <objects_type>:   The type of the objects (default Genes)\n";
  print "      -ot <object_type>:    The type of the object (default Gene)\n";
  print "      -oi <object_id>:      The identifier name of the object (default ORF)\n";
  print "      -t  <threshold>:      Only attributes above this threshold will enter the attribute list (default 5)\n\n";
}

1
