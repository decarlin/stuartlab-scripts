#!/usr/bin/perl

use strict;

if (length($ARGV[2]) == 0)
{
  print <DATA>;
  exit;
}

my $infile = $ARGV[0];
my $outfile = $ARGV[1];
my $organism = $ARGV[2];
my @go_file;
@go_file[0] = "component.ontology.flat";
@go_file[1] = "function.ontology.flat";
@go_file[2] = "process.ontology.flat";
my $hier = "go.hierarchy.flat";

open (INFILE, "<$infile") or die "Can't open $infile.\n";
open (OUTFILE, ">$outfile");

open(GO0, "<@go_file[0]") or die "Can't open @go_file[0].\n";
open(GO1, "<@go_file[1]") or die "Can't open @go_file[1].\n";
open(GO2, "<@go_file[2]") or die "Can't open @go_file[2].\n";

open(HIER, "<$hier") or die "Can't open $hier.\n";

my %hash;
while (my $go_line = <GO1>)
{
   chop ($go_line);
   my ($id_key, $att_value) = split(/\t/, $go_line);
   $hash{$id_key} = $att_value;
}

while (my $go2_line = <GO2>)
{
   chop($go2_line);
   my ($id_key, $att_value) = split(/\t/, $go2_line);
   $hash{$id_key} = $att_value;
}

while (my $go3_line = <GO0>)
{
   chop($go3_line);
   my ($id_key, $att_value) = split(/\t/, $go3_line);
   $hash{$id_key} = $att_value;
}

my %hash_hier;
while(<HIER>)
{
   chop;

   my @row = split(/[\s\t]/);

   my $num_ancestors = @row;
   my $id = $row[$num_ancestors - 1];

   my %all_ancestors;
   for (my $i = 0; $i < @row; $i++)
   {
     if (length($row[$i]) > 0)
     {
       $all_ancestors{$row[$i]} = "1";
     }
   }

   my $ancestors_str = "";
   foreach my $key (keys %all_ancestors)
   {
     $ancestors_str .= "$key\t";
   }

   $hash_hier{$id} = $ancestors_str;
}

my $counter = 0;

#----------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------
sub get_orf_name (\@)
{
  my ($row_str) = @_;

  my $res = "";

  my @row = @$row_str;

  if ($organism eq "yeast" || $organism eq "Yeast")
  {
    if (@row[2] =~ /(Y[A-Z][A-X][0-9][0-9][0-9][CW][\-A-Z]*)/)
    {
      $res = $1;
    }
    elsif (@row[10] =~ /(Y[A-Z][A-X][0-9][0-9][0-9][CW][\-A-Z]*)/)
    {
      $res = $1;
    }
  }
  elsif ($organism eq "worm" || $organism eq "Worm")
  {
    if (@row[2] =~ /([A-Z][^\s]+[\.][^\s]+)/)
    {
      $res = $1;
    }
    elsif (@row[10] =~ /([A-Z][^\s]+[\.][^\s]+)/)
    {
      $res = $1;
    }
  }
  elsif ($organism eq "fly" || $organism eq "Fly")
  {
    $res = @row[1];
  }
  elsif ($organism =~ /Human/i)
  {
    $res = @row[1];
  }
  elsif ($organism =~ /MetaGene/i)
  {
    $res = @row[0];
  }
  else
  {
    $res = @row[1];
  }

  return $res;
}

<INFILE>;
<INFILE>;

while (<INFILE>)
{
  chop;

  my @row = split (/\t/);

  my $orf = get_orf_name(@row);

  my $go_code_col = $organism =~ /MetaGene/i ? 1 : 4;

  #print "$orf\n";

  if (length($orf) > 0)
  {
    my $hier_hash_line = $hash_hier{$row[$go_code_col]};
    my @curr_hiers = split(/\t/, $hier_hash_line);
    for (my $i = 0; $i < @curr_hiers; $i++)
    {
      my $go_att_name = $hash{$curr_hiers[$i]};

      print OUTFILE "$orf\t$go_att_name\n";
    }
  }
}

__DATA__

Usage: parse_gene_associations.pl <associations file> <output file> <organism>



  return $res;
}

<INFILE>;
<INFILE>;

while (<INFILE>)
{
  chop;

  my @row = split (/\t/);

  my $orf = get_orf_name(@row);

  #print "$orf\n";

  if (length($orf) > 0)
  {
    my $hier_hash_line = $hash_hier{$row[4]};
    my @curr_hiers = split(/\t/, $hier_hash_line);
    for (my $i = 0; $i < @curr_hiers; $i++)
    {
      my $go_att_name = $hash{$curr_hiers[$i]};

      print OUTFILE "$orf\t$go_att_name\n";
    }
  }
}

__DATA__

Usage: parse_gene_associations.pl <associations file> <output file> <organism>


