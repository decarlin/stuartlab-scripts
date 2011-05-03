#!/usr/bin/perl

require("$ENV{HOME}/develop/perl/GeneXPress/extract_regulators.pl");

use strict;
# use GraphViz;

my $arg;
my $verbose=1;
my @cluster_files;
my $regulator_file='';
my $delim = "\t";
my $max_depth = -1;
my $lists_format = 0;
my $suppress_orfs = 1;
my $regs_only = 0;
my $pvalue_cutoff=.001;
my $desc_file = '';

# my %org_url_base =
# {
#   "yeast" => "http://www.proteome.com/databases/WormPD/reports/",
#   "worm"  => "http://www.proteome.com/databases/YPD/reports/"
# };
my %org_url_base;
$org_url_base{'yeast'} = 'http://www.proteome.com/databases/WormPD/reports/';
$org_url_base{'worm'} = 'http://www.proteome.com/databases/YPD/reports/';

my $url_base='';
my $organism = 'yeast';

#######################################################
##
## Graph preferences and defaults
##

# Global graph properties
my $random_start=0;
my $concentrate=0;
my $width=8;
my $height=10.5;
my $print_format='dot';

# Node choices
my $reg_fontsize=10;
my $orf_fontsize=10;
my $clu_fontsize=10;
my $ann_fontsize=10;

my $reg_color='yellow';
my $clu_color='green';
my $orf_color='white';
my $ann_color='pink';

my $reg_shape='ellipse';
my $orf_shape='ellipse';
my $clu_shape='box';
my $ann_shape='hexagon';

my $reg_style='filled';
my $orf_style='filled';
my $clu_style='filled';
my $ann_style='filled';

##
#######################################################

while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-depth')
  {
    $max_depth = int(shift @ARGV);
  }
  elsif($arg eq '-lists')
  {
    $lists_format = 0;
  }
  elsif($arg eq '-desc')
  {
    $desc_file = shift @ARGV;
  }
  elsif($arg eq '-orfs')
  {
    $suppress_orfs = 0;
  }
  elsif($arg eq '-regs')
  {
    $regs_only = 1;
  }
  elsif($arg eq '-pv')
  {
    $pvalue_cutoff = shift @ARGV;
  }
  elsif($arg eq '-org')
  {
    $organism = shift @ARGV;
  }
  elsif($arg eq '-url')
  {
    $url_base = shift @ARGV;
  }
  elsif($arg eq '-r')
  {
    $random_start = 1;
  }
  elsif($arg eq '-o')
  {
    $print_format = shift @ARGV;
  }
  elsif((-f $arg) and length($regulator_file)<1)
  {
    $regulator_file = $arg;
  }
  elsif(-f $arg)
  {
    push(@cluster_files,$arg);
  }
  else
  {
    print STDERR "Bad argument '$arg' given.  Use --help for help.\n";
    exit(1);
  }
}

# Try to get a URL base for linking text in nodes:
if(length($url_base)<1)
{
  if(exists($org_url_base{$organism}))
  {
    $url_base = $org_url_base{$organism};
  }
}


if(length($regulator_file)<1)
{
  print STDERR "Must supply a regulator file.  Use the --help flag for help.\n";
  exit(-2);
}

# Read in descriptions from a seperate file
my $desc;
my %descriptions;
if(-f $desc_file)
{
  open(FILE, $desc_file) 
    or die("Could not open description file '$desc_file'.\n");
  while(<FILE>)
  {
    if(/\S/)
    {
      chop;
      my($or,$na,$de) = split("\t");
      $descriptions{$or} = $na . ' ' . $de;
    }
  }
  close(FILE);
}

# if(not(open(REG,$regulator_file)))
# {
#   print STDERR "Could not open the regulator file '$regulator_file'.\n";
#   exit(-2);
# }

my $line=0;
my %clu2reg; # maps cluster files to their regulators.

not($verbose) or print STDERR "Reading regulator file '$regulator_file'...";
my $clu;
my $reg;
my @regs;

my %orf2clu; # keep track of which cluster an ORF is in.

# Edges
my %reg2clu_edges;
my %ann2clu_edges;
my %reg2orf_edges;
my %reg2reg_edges;

# Nodes
my %reg_nodes;
my %ann_nodes;
my %orf_nodes;
my %clu_nodes;

my $orf;
my $depth;
my @extracted_regulators = &extract_regulators($regulator_file);
my %depths;
my $N=0; # Number of nodes encountered.
my $E=0; # Number of edges encountered.
# while(<REG>)
while(@extracted_regulators)
{
  $_ = shift(@extracted_regulators);
  if(/\S/ and not(/^\s*#/))
  {
    ($clu,@regs) = split($delim);
    if($clu =~ /\S/)
    {
      $N++;
      $clu_nodes{$clu} = $N;
      for(my $i=0; $i<=$#regs; $i++)
      {
        ($reg,$depth) = split(' ', $regs[$i]);
	# print STDERR "'$reg' '$depth'\n";
        $reg = &fix_eran_worm_name($reg);
        if($reg=~/\S/ and ($max_depth==-1 or $depth<=$max_depth))
        {
	  $E++;
          $reg2clu_edges{$reg . $delim . $clu} = $E;
	  $N++;
          $reg_nodes{$reg} = $N;

	  if(not(exists($depths{$clu,$reg})))
	  {
	    if(exists($clu2reg{$clu}))
	    {
	      $clu2reg{$clu} .= "\t$reg";
	    }
	    else
	    {
	      $clu2reg{$clu} = $reg;
	    }
	  }

	  $depths{$clu,$reg} = $depth;
        }
      }
    }
  }
}
# close(REG);
not($verbose) or print STDERR " done.\n";

if($#cluster_files<0)
{
  print STDERR "Must supply at least one cluster file.\n";
  exit(-3);
}

my $count;
my $orf;
my $gene;
my $ann;
my $ann_info;
my $ann_val;
my $ann_pvalue;
my $ann_hits;
my $ann_num;
my $fsm = 'get_cluster';
my %orf_cluster_count;
my %genes;
while(@cluster_files)
{
  my $file = shift @cluster_files;
  if(not(open(FILE,$file)))
  {
    not($verbose) or 
      print STDERR "Could not open cluster file '$file'.  Skipping.\n";
  }
  else
  {
    not($verbose) or print STDERR "Reading file '$file'...";

    if(not($lists_format))
    {
      $clu = '';
      while(<FILE>)
      {
	chop;
        if(/^Cluster\s+(\d+)/)
	{
	  $clu = int($1);
          if(not(exists($clu2reg{$clu})) or length($clu2reg{$clu})<1)
          {
            not($verbose) or 
               print STDERR "No regulator known for cluster '$clu'.\n";
            exit(-2);
          }
          @regs = split($delim,$clu2reg{$clu});
	  # print STDERR "Regulator '", join($delim,@regs), "'\n";
	  $fsm='get_annotation_start';
	  # print STDOUT "get_annotation_start\n";
	}
	elsif(/\S/ and not(/^\s*[=]+\s*$/) and $fsm eq 'get_annotations')
	{
	  ($ann,$ann_info) = split('=');
	  $ann = &clean_name($ann);
	  ($ann_val,$ann_pvalue,$ann_hits,$ann_num) = split("\t",$ann_info);
	  if($ann_pvalue<=$pvalue_cutoff)
	  {
	    $N++;
	    $ann_nodes{$ann} = $N;
	    $E++;
	    $ann2clu_edges{$clu . $delim . $ann} = $E;
	    # print STDOUT "annotation edge: '$clu' -> '$ann' added.\n";
	  }
	}
	elsif(/\S/ and not(/^\s*[=]+\s*$/) and $fsm eq 'get_orfs')
	{
	  my $gene_desc;
          ($orf,$gene_desc) = split($delim);
	  ($gene,$desc) = split('-',$gene_desc);
	  $gene = &fix_eran_worm_name($gene);
	  $gene = &clean_name($gene);
	  $desc = &clean_name($desc);
	  # print STDERR "[$gene] [$desc]\n";
	  $orf = &fix_eran_worm_name($orf);
	  $genes{$orf} = $gene;
	  if(not(exists($descriptions{$orf})))
	  {
	    $descriptions{$orf} = $desc;
	  }
	  if(exists($orf2clu{$orf}))
	  {
	    print STDERR "WARNING: ORF '$orf' in both '$clu'",
	                   " and '$orf2clu{$orf}'!\n";
	  }

	  # my $mydepth = ($max_depth==-1 or $max_depth>$#regs) ? 
	  #                 $#regs : $max_depth;
	  # print STDERR "[$mydepth] [$max_depth] [$#regs]\n";
	  # for(my $i=0; $i<=$mydepth; $i++)
	  my $orf_is_reg=0;
	  for(my $i=0; $i<=$#regs; $i++)
	  {
	    if($max_depth<0 or $depths{$clu,$regs[$i]}<=$max_depth)
	    {
	      # print STDERR "[$clu] [$regs[$i]] [$max_depth] <=> [$depths{$clu,$regs[$i]}]\n";
	      # The ORF is a regulator.
	      if($reg_nodes{$orf})
	      {
		$E++;
	        $reg2reg_edges{$regs[$i] . $delim . $orf} = $E;
		$orf_is_reg=1;
	      }
	      else
	      {
		$E++;
                $reg2orf_edges{$regs[$i] . $delim . $orf} = $E;
	      }
	    }
	  }
	  if(not($orf_is_reg))
	  {
	    $orf_cluster_count{$orf} = exists($orf_cluster_count{$orf}) ?
	                             $orf_cluster_count{$orf} + 1 : 1;
	    $count = $orf_cluster_count{$orf};
	    $N++;
            $orf_nodes{$orf} = $N;
	    $orf2clu{$orf} = $clu;
	  }
	  # print STDOUT "'", join(":",@regs), "' -> '$orf' found (orf count = $count)\n";
	  # print STDOUT "<no change>\n";
	}
	elsif(/^\s*[=]+\s*$/ and $fsm eq 'get_annotation_start')
	{
	  $fsm = 'get_annotations';
	  # print STDOUT "get_annotations\n";
	}
	elsif(/^\s*[=]+\s*$/ and $fsm eq 'get_annotations')
	{
	  $fsm = 'get_orfs';
	  # print STDOUT "get_orfs\n";
	}
      }
    }
    elsif($file =~ /^(\d+)/)
    {
      $clu = int($1);

      if(not(exists($clu2reg{$clu})) or length($clu2reg{$clu})<1)
      {
        not($verbose) or 
           print STDERR "No regulator known for cluster '$clu'.\n";
        exit(-2);
      }
      # $reg = $clu2reg{$clu};
      @regs = split($delim, $clu2reg{$clu});
      while(<FILE>)
      {
        chop;
        ($orf) = split($delim);
        $orf = &fix_eran_worm_name($orf);
	$genes{$orf} = $gene;
	$descriptions{$orf} = $desc;
        if(exists($orf2clu{$orf}))
        {
          print STDERR "ORF '$orf' in both '$clu' and '$orf2clu{$orf}'!\n";
	}

	# foreach $reg (@regs)
	my $mydepth = ($max_depth==-1 or $max_depth>$#regs) ? 
	                $#regs : $max_depth;
	# print STDERR "[$mydepth] [$max_depth] [$#regs]\n";
	# for(my $i=0; $i<=$mydepth; $i++)
	my $orf_is_reg=0;
	for(my $i=0; $i<=$#regs; $i++)
	{
	  if($max_depth<0 or $depths{$clu,$regs[$i]}<=$max_depth)
	  {
	    if(exists($reg_nodes{$orf}))
	    {
	      $E++;
	      $reg2reg_edges{$regs[$i] . $delim . $orf} = $E;
	      $orf_is_reg=1;
	    }
	    else
	    {
	      $E++;
              $reg2orf_edges{$regs[$i] . $delim . $orf} = $E;
	    }
	  }
	}
	if(not($orf_is_reg))
	{
	  $orf_cluster_count{$orf} = exists($orf_cluster_count{$orf}) ?
	                             $orf_cluster_count{$orf} + 1 : 1;
	  $N++;
          $orf_nodes{$orf} = $N;
	  $orf2clu{$orf} = $clu;
	}
      }
    }
    not($verbose) or print STDERR " done.\n";
    close(FILE);
  }
}

# Count some stuff.
my $num_reg_nodes = scalar(keys(%reg_nodes))+1;
my $num_orf_nodes = scalar(keys(%orf_nodes))+1;
my $num_clu_nodes = scalar(keys(%clu_nodes))+1;
my $num_ann_nodes = scalar(keys(%ann_nodes))+1;
my $num_reg_edges = scalar(keys(%reg2clu_edges))+1;
my $num_orf_edges = scalar(keys(%reg2orf_edges))+1;
my $num_ann_edges = scalar(keys(%ann2clu_edges))+1;
my $num_reg_reg_edges = scalar(keys(%reg2reg_edges))+1;

$verbose and print STDERR "Constructing graph with:\n",
  "$N total nodes\n",
  "$E total edges\n",
  "$num_reg_nodes regulator nodes\n",
  ($suppress_orfs ? "" : "$num_orf_nodes ORF nodes\n"),
  "$num_clu_nodes cluster nodes\n",
  "$num_orf_nodes ORF nodes\n",
  ($suppress_orfs ? " (suppressed)\n" : "\n"),
  "$num_ann_nodes annotation nodes\n",
  "$num_reg_edges edges from regulators to clusters\n",
  "$num_reg_reg_edges edges from regulators to regulators\n",
  "$num_orf_edges edges from regulators to ORFs",
  ($suppress_orfs ? " (suppressed)\n" : "\n"),
  "$num_ann_edges edges from clusters to annotations\n",
  "Annotation p-value cutoff = $pvalue_cutoff\n",
  ($suppress_orfs ? "" : "Excluding ORF nodes.\n");

# Construct the graph
# my $g = GraphViz->new
# (
#   directed => 0,
#   random_start => $random_start,
#   concentrate => $concentrate,
#   width => $width,
#   height => $height
# );

# Made graphs too stretched (edges too long and hard to follow).  This
# is because using the ratio=fill line.
#
# print "digraph GeneXPress {\n",
#       "  graph [size = \"$width,$height\",\n",
#       "         ratio = fill ];\n",
#       "  node [ label = \"\\N\" ];\n";

print "digraph GeneXPress {\n",
      "  graph [size = \"$width,$height\"];\n",
      "  node [ label = \"\\N\" ];\n";

# When names don't look like valid Dotty names, we
# convert them and assign them an identifier.
my %friendly_names;
my $num_friendly=0;
my $id;

# Add all the regulator nodes to the graph.
foreach $reg (keys(%reg_nodes))
{
  if($reg =~ /\S/)
  {
    my $my_url = length($url_base)>0 ? $url_base . $reg . '.html' : ''; 
    # $g->add_node
    # (
    #   $reg,
    #   label => $reg,
    #   color => $reg_color,
    #   style => $reg_style,
    #   fontsize => $reg_fontsize,
    #   shape => $reg_shape,
    #   url   => $my_url
    # );
    my $label = &make_label($reg,\%genes,\%descriptions);
    &print_node($reg_nodes{$reg},$label, $reg_color,$reg_style,$reg_fontsize,$reg_shape,$my_url);
  }
}

# Add all the annotations
if(not($regs_only))
{
  foreach $ann (keys(%ann_nodes))
  {
    # print STDERR "Annotation node '$ann' being added.\n";
    if($ann =~ /\S/)
    {
      # $g->add_node
      # (
      #   $ann,
      #   label => &chunk($ann,10),
      #   color => $ann_color,
      #   style => $ann_style,
      #   fontsize => $ann_fontsize,
      #   shape => $ann_shape
      # );
      &print_node($ann_nodes{$ann},&chunk($ann,10), $ann_color,$ann_style,$ann_fontsize,$ann_shape,'NOURL');
    }
  }
}

# Add all the cluster nodes
if(not($regs_only))
{
  foreach $clu (keys(%clu_nodes))
  {
    if($clu =~ /\S/)
    {
      # $g->add_node
      # (
        # $clu,
        # label => ('Cluster\n' . "$clu"),
        # color => $clu_color,
        # style => $clu_style,
        # fontsize => $clu_fontsize,
        # shape => $clu_shape
      # );
      &print_node($clu_nodes{$clu},('Cluster\n' . "$clu"), $clu_color,$clu_style,$clu_fontsize,$clu_shape,'NOURL');
    }
  }
}


if(not($regs_only) and not($suppress_orfs))
{
  # Add all the ORF nodes
  foreach $orf (keys(%orf_nodes))
  {
    # Make sure the ORF is not a regulator.
    if($orf =~ /\S/ and not(exists($reg_nodes{$orf})))
    {
      my $my_url = length($url_base)>0 ? $url_base . $orf . '.html' : ''; 
      # $g->add_node
      # (
      #   $orf,
      #   label => $orf,
      #   color => $orf_color,
      #   style => $orf_style,
      #   fontsize => $orf_fontsize,
      #   shape => $orf_shape,
      #   url => $my_url
      # );
      my $label = &make_label($reg,\%genes,\%descriptions);
      &print_node($orf_nodes{$orf},$label,$orf_color,$orf_style,$orf_fontsize,$orf_shape,$my_url);
    }
  }
}

my $edge;
# Output edges from regulators to ORFs
if(not($regs_only) and not($suppress_orfs))
{
  foreach $edge (keys(%reg2orf_edges))
  {
    ($reg,$orf) = split($delim,$edge);

    if($reg =~ /\S/)
    {
      # $g->add_edge
      # (
      #   $reg => $orf,
      #   dir => 'forward'
      # );
      &print_edge($reg_nodes{$reg}, $orf_nodes{$orf}, 'forward', 'NOSTYLE');
    }
  }
}

# Output edges from regulators to clusters
if(not($regs_only))
{
  foreach $edge (keys(%reg2clu_edges))
  {
    ($reg,$clu) = split($delim,$edge);
    if($reg =~ /\S/ and $clu =~ /\S/)
    {
      # print "$reg\t$clu\n";
      # $g->add_edge
      # (
      #   $reg => $clu,
      #   dir => 'forward'
      # );
      &print_edge($reg_nodes{$reg}, $clu_nodes{$clu}, 'forward', 'NOSTYLE');
    }
  }
}

# Output edges from annotations to clusters
if(not($regs_only))
{
  foreach $edge (keys(%ann2clu_edges))
  {
    ($clu,$ann) = split($delim,$edge);
    if($clu =~ /\S/ and $ann =~ /\S/)
    {
      # $g->add_edge
      # (
      #   $clu => $ann,
      #   dir => 'none'
      # );
      &print_edge($clu_nodes{$clu}, $ann_nodes{$ann}, 'none', 'NOSTYLE');
    }
  }
}

# Output edges from regulators to regulators
my($reg1,$reg2);
foreach $edge (keys(%reg2reg_edges))
{
  ($reg1,$reg2) = split($delim,$edge);
  if($reg1 =~ /\S/ and $reg2 =~ /\S/)
  {
    # print STDERR "'$reg1' '$reg2'\n";
    # print "$reg1\t$reg2\n";
    # if($reg2 eq 'YDR168W')
    #   { print STDERR "!!!\n"; }
    # $g->add_edge
    # (
    #   $reg1 => $reg2,
    #   dir => 'forward'
    # );
    &print_edge($reg_nodes{$reg1}, $reg_nodes{$reg2}, 'forward', 'NOSTYLE');
  }
}

# Add invisible edges for prettier layout

# TEST: add one invisible edge
# my @regstmp = keys(%reg_nodes);
# my $regtmp = $regstmp[5];
# my @clustmp = keys(%clu_nodes);
# my $clutmp = $clustmp[5];
# print STDERR "Adding invisible edge '$regtmp' -- '$clutmp'\n";
# $g->add_edge
# (
#   $regtmp => $clutmp,
#   style => 'invis'
# );

# REGULATOR---CLUSTER: Edges from every regulator to every cluster.
# foreach $reg (keys(%reg_nodes))
# {
#  if($reg =~ /\S/)
#  {
#    foreach $clu (keys(%clu_nodes))
#    {
#      if($clu =~ /\S/)
#      {
#        $g->add_edge
#        (
#          $reg => $clu,
#          style => 'invis',
#          dir => 'none'
#        );
#      }
#    }
#  }
#}

# CLUSTER---ANNOTATION: Edges from every cluster to every annotation.
# This only looks good when outputting to dotty format. (why?)
# if(not($regs_only) and $print_format eq 'dot')
# {
#   my @clusters = keys(%clu_nodes);
#   for(my $c=0; $c<$#clusters; $c++)
#   {
#     # $g->add_edge
#     # (
#     #   $clusters[$c] => $clusters[$c+1],
#     #   style => 'invis',
#     #   dir => 'none'
#     # );
#     &print_edge($clu_nodes{$clusters[$c]},$clu_nodes{$clusters[$c+1]},'none','invis');
#   }
# }
# if(not($regs_only))
# {
#   my @clusters = keys(%clu_nodes);
#   for(my $i=0; $i<$#clusters; $i++)
#   {
    # for(my $j=0; $j<=$#clusters; $j++)
    # {
    #   &print_edge($clu_nodes{$clusters[$i]},$clu_nodes{$clusters[$j]},'none','invis');
    # }
#     &print_edge($clu_nodes{$clusters[$i]},$clu_nodes{$clusters[$i+1]},'none','invis');
#   }
# }

print "}";

# $verbose and print STDERR "Printing out the graph...";
# if($print_format eq 'dot')
#   { print STDOUT $g->as_canon; }
# elsif($print_format eq 'ps')
#   { print STDOUT $g->as_ps; }
# elsif($print_format eq 'gif')
#   { print STDOUT $g->as_gif; }
# elsif($print_format eq 'jpg')
#   { print STDOUT $g->as_jpeg; }
# elsif($print_format eq 'imap')
#   { print STDOUT $g->as_imap; }
# elsif($print_format eq 'txt')
#   { print STDOUT $g->as_plain; }
# elsif($print_format eq 'png')
#   { print STDOUT $g->as_png; }
# elsif($print_format eq 'wbmp' or $print_format eq 'bmp')
#   { print STDOUT $g->as_wbmp; }
# elsif($print_format eq 'vrml')
#   { print STDOUT $g->as_vrml; }
# $verbose and print STDERR " done.\n";

exit(0);

sub clean_name
{
  my $name = shift;
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  $name =~ s/(\s)\s+/\1/g;
  return $name;
}

# sub fix_eran_worm_name
# {
#   my $orf = shift;
#   $orf =~ s/_([^_]+)\s*$/.\1/;
#   return $orf;
# }

sub chunk
{
  my $name = shift;
  my $inc=shift;
  my $chunks;
  for(my $i=0; $i<length($name); $i+=$inc)
  {
    my $len = length($name)-$i;
    $len = $len>$inc ? $inc : $len;
    $chunks .= ($i>0 ? '\n' : '') . substr($name,$i,$len);
  }
  return $chunks;
}

sub print_node
{
  my($id,$label,$color,$style,$fontsize,$shape,$url) = @_;
  print "  node$id [label=\"$label\", ",
        "color=$color, ",
	"fontsize=$fontsize, ",
	"shape=$shape, ",
	"style=$style",
	($url eq 'NOURL' ? "" : ", url=\"$url\""),
	"];\n";
}

sub print_edge
{
  my($i, $j, $dir, $style) = @_;
  if($i=~/\S/ and $j=~/\S/)
  {
    print "  node$i -> node$j [dir=$dir",
          ($style eq 'NOSTYLE' ? "" : ", style=$style"),
  	"];\n";
  }
}

sub make_label # ($reg,\%genes,\%descriptions)
{
  my $orf = shift;
  my $genes_ref = shift;
  my $descriptions_ref = shift;
  my %genes = %$genes_ref;
  my %descriptions = %$descriptions_ref;
  my $label='';

  if(exists($genes{$orf}) and $orf ne $genes{$orf})
  {
    $label = $orf . ' ' . $genes{$orf};
  }
  else
  {
    $label = $orf;
  }

  if(exists($descriptions{$orf}))
  {
    $label .= '\n' . &chunk(substr($descriptions{$orf},0,100),20);
  }
  return $label;
}


__DATA__

syntax: genexpress2dotty.pl [OPTIONS] TSC GENEXPRESS

TSC - Two-sided clustering file.  Contains clusters with their attribute
      splits in XML format.

GENEXPRESS - GeneXPress cluster files (*.gxc usual extension) produced
	     by printing cluster modules from within GeneXPress.  Multiple
	     files can be supplied if desired.

OPTIONS are:

  -q: Quiet mode: turn verbosity off (default verbose)
  -depth D: Only use regulators at depth D.  -1 means infinite (default).
  -lists: Instead of supplying a single GENEXPRESS file, multiple files with
        genelists are supplied.
  -desc FILE: tell the script that gene descriptions can be found in the file
              FILE.  If 3 columns are in the file then it is assumed to be
	      in the format:

	      ORF <tab> NAME <tab> DESCRIPTION.

  -orfs: print out single ORF nodes as well (default suppresses printing).
  -regs: print regulators *only* (trumps the -orfs flag)
  -org ORGANISM: Set the organism to ORGANISM (default is yeast).
  -url URL: Set the base url for linking nodes to URL (default uses organism
            to determine if a URL is known; e.g. link to Proteome is used for
	    worm and yeast).
  -r: Uses a random initialization for graph layout to produce a different
      graph even though run on same input data (default is non-random).
  -o FORMAT: set the output format to FORMAT.  Valid values for FORMAT are:

	dot  - dotty text format (default)
	ps   - postscript format
	gif  - graphics interchange formatted file
	jpg  - JPEG graphics formatted file
	png  - PNG graphics
	wbmp - windows BMP
	imap - an image map for HTML
	txt  - plain text (same as dot?)
	vrml - produces a VRML 

  -pv CUTOFF: set the p-value cutoff to CUTOFF.  Annotations with p-values
              equal to or less than this will be included in the graph.  
	      Default is 0.001.
	

