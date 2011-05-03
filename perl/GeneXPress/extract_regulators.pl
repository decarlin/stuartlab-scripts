#! /usr/bin/perl

use strict;

#--------------------------------------------------------------------------------
# EXTRACT_REGULATORS
#--------------------------------------------------------------------------------
sub extract_regulators
{
  my $genexpress_file = shift;
  my @extracted_lines;

  open(GENEXPRESS_FILE, "<$genexpress_file")
     or die "Could not open genexpress file '$genexpress_file'\n";

  my @id_stack;
  my @attribute_stack;
  my $depth = 0;;
  my @clusters;
  my $counter = 0;
  my $return_depth = undef;
  my $return_cluster = undef;
  my $cluster = undef;
  my $attrib = undef;
  my %regulators = undef;

  while(<GENEXPRESS_FILE>)
  {
    chop;

    if (/[\<]Root/ || /[\<]Child/)
    {
      /ClusterNum=[\"]([0-9]+)[\"]/;

      $cluster = &fix($1);
      $id_stack[$depth] = $cluster;

      /SplitAttribute=[\"]([^\s]+)[\"]/;

      $attrib = &fix($1);
      $attribute_stack[$depth] = $attrib;

      if(not(defined($return_depth)) and $attrib ne 'g_cluster')
      {
        $return_depth   = $depth;
        $return_cluster = $cluster;

	if(length($attrib)>0 and length($cluster)>0 and
	    $attrib ne $cluster)
	{
	   # print "$cluster $attrib";
	   # $regulators{$attrib}++;
	   $regulators{$attrib} = 0;
	}
      }

      elsif(defined($return_depth))
      {
        if($depth <= $return_depth)
        {
	  if(defined(%regulators))
	  {
	    # print "$return_cluster\t",join("\t",keys(%regulators)),"\n";
	    # &print_regulators($return_cluster,\%regulators);
            push(@extracted_lines,
	           &format_regulators($return_cluster,\%regulators));
	  }
	  %regulators = undef;

	  if(length($attrib)>0 and length($cluster)>0 and
	       $attrib ne $cluster) 
	  {
	     # print "\n$cluster $attrib";
	     # $regulators{$attrib}++;
	     $regulators{$attrib} = 0;
	  }
          $return_cluster = $cluster;
          $return_depth   = $depth;
        }
        else
        {
          if($attrib ne $cluster and
                length($attrib)>0 and length($cluster)>0 and
		not(exists($regulators{$attrib})))
	  {
             # print " $attrib";
	     # $regulators{$attrib}++;
	     $regulators{$attrib} = $depth-$return_depth;
	  }
        }
      }

      # print "\n[cluster '$cluster' ",
      #                "attribute '$attrib' ",
      #                "depth '$depth'] return depth '$return_depth' ",
      #                "return cluster '$return_cluster'\n";
      # if ($depth > 0 && $attribute_stack[$depth - 1] eq $attribute && $attribute_stack[$depth] ne $attribute)
      # {
      #   $clusters[$counter++] = $id_stack[$depth];
      # }

      $depth++;
    }

    elsif (/[\<][\/]Root[\>]/ || /[\<][\/]Child[\>]/)
    {
      $depth--;
    }
  }

  if(scalar(keys(%regulators))>=0)
  {
    # print "$return_cluster\t", join("\t",keys(%regulators)), "\n";
    push(@extracted_lines,&format_regulators($return_cluster,\%regulators));
  }
  
  return @extracted_lines;
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
# if (length($ARGV[0]) > 0)
# {
#   &extract_regulators($ARGV[0]);
# }
# else
# {
#   print <DATA>;
# }

sub print_regulators # ($return_cluster,%regulators)
{
  my $cluster = shift;
  my $regulators_ref = shift;
  my %regulators = %$regulators_ref;
  my @regulator_list;

  foreach my $regulator (keys(%regulators))
  {
    if($regulator =~ /\S/)
    {
      my $depth = $regulators{$regulator};
      $regulator = &fix_eran_worm_name($regulator);
      push(@regulator_list,"$regulator $depth");
    }
  }
  @regulator_list = sort by_depth @regulator_list;

  print "$cluster";
  foreach my $regulator (@regulator_list)
  {
    print "\t$regulator";
  }
  print "\n";
}

sub format_regulators # ($return_cluster,%regulators)
{
  my $cluster = shift;
  my $regulators_ref = shift;
  my %regulators = %$regulators_ref;
  my @regulator_list;

  foreach my $regulator (keys(%regulators))
  {
    if($regulator =~ /\S/)
    {
      my $depth = $regulators{$regulator};
      $regulator = &fix_eran_worm_name($regulator);
      push(@regulator_list,"$regulator $depth");
    }
  }
  @regulator_list = sort by_depth @regulator_list;

  # print "$cluster";
  my $result = $cluster;
  foreach my $regulator (@regulator_list)
  {
    # print "\t$regulator";
    $result .= "\t$regulator";
  }
  return $result;
}

sub fix
{
  my $name = shift;
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  $name =~ s/(\s)\s+$/\1/;
  return $name;
}

sub fix_eran_worm_name
{
  my $orf = shift;
  $orf =~ s/_([^_]+)\s*$/.\1/;
  return $orf;
}

sub by_depth
{
  my($reg_a,$depth_a) = split(' ', $a);
  my($reg_b,$depth_b) = split(' ', $b);
  return($depth_a <=> $depth_b);
}

1

