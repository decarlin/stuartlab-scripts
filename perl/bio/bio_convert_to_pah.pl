#! /usr/bin/perl

# ************************************************* 
# gt_converter.pl
#
# Purpose: Convert raw data output into an xml file
#          to be used with the GeneTool visualization program
#
# Inputs:  Raw data file
#
# Outputs: xml file
#
# ************************************************* 
#
# Initial design by: Tuan Pham
# 1 August 2001
#
# CURIS Summer 2001
# Stanford University
# 
# ************************************************* 
#
# Modified by: 
#
#

die "\n\n",
    "Usage: ",
    "  $0 <raw data file> <root node alias OR -{#obj to generate}>\n\n"
    if (@ARGV < 1);


# Main
# ----
# 1) Parse file to seed data structures
# 2) Output reformatted in xml


## Requirements ##
#require 5.000;
#use strict;

## Globals ##
$main::GEN_DATA = 0;
%main::global_kids_printed = {};

## Data structures ##
my %nodeAliasH;
my %nodeIDH;
my %childH;
my %objH;
my %nodeDataH;
my $root;

if (@ARGV == 2) {
  if ($ARGV[1] =~ m/-/) {
    $ARGV[1] =~ s/-//;
    $main::GEN_DATA = $ARGV[1];
  }

  else {
    $root = $ARGV[1];
    $main::GEN_DATA = 0;
  }
}



seedDataStructs($ARGV[0], \%nodeAliasH, \%nodeIDH,
		\%childH, \%objH, \%nodeDataH, \$root);

if ($main::GEN_DATA == 0) {
  outputXMLFile($ARGV[0], \%nodeAliasH, \%childH, 
		\%objH, \%nodeDataH, $root);
}


## seedDataStructs
## ---------------
## Read the file with each line seeding approp. struct

sub seedDataStructs {
  my ($file, $rNodeAliasH, $rNodeIDH,
      $rChildH, $rObjH, $rNodeDataH, $rRoot) = @_;
  my ($line);

  ## Open the files for analysis ##
  open (INFILE, $file) || die "Cannot open $file for reading!\n";

  readNodeSection($rNodeAliasH, $rNodeIDH);
  readEdgeSection($rChildH, $rRoot);
  readDataSection($rObjH, $rNodeDataH);

  close INFILE;

  if ($main::GEN_DATA) {
    genMoreDataObj($file, $rObjH, $rNodeDataH, $rNodeIDH);
  }
}



## readNodeSection
## ---------------
## 1st line: NumNodes=[#]
## Followed: Node[id]=[alias]
##
## Goal: Seed the $rNodeIDH {alias} -> id
##       Seed the $rNodeAliasH {id} -> alias

sub readNodeSection {
  my ($rNodeAliasH, $rNodeIDH) = @_;
  my ($line, @parsed);
  my ($numNodes, $id, $alias);
  
  $found_num_nodes = 0;
  while ($found_num_nodes == 0)
  {
	$line = <INFILE>;
	chomp $line;
	@parsed = split(/=/, $line);

	if ($parsed[0] eq "NumNodes")
	{
	  $numNodes = $parsed[1];
	  #print "\n### NUM NODES = $numNodes! ###\n";
	  $found_num_nodes = 1;
	}
  }

  for (my $i=0; $i<$numNodes; $i++) 
  {
    $line = <INFILE>;
    chomp $line;

    @parsed = split(/=/, $line);
    
    $id = $parsed[0];
    $id =~ s/Node//;

    $alias = $parsed[1];

    #print "Node: $id -> $alias\n";

    $rNodeAliasH->{$alias} = $id;
    $rNodeIDH->{$id} = $alias;
  } 
}



## readEdgeSection
## ---------------
## Line: Edge=[parent alias],[child alias]
## Last: NumEdges=[#]
##
## Goal: Seed the child hashtable {parent} -> @children (by alias)

sub readEdgeSection {
  my ($rChildH, $rRoot) = @_;
  my ($line, @parsed);
  my ($numEdges, $parent, $child);
  my %isChild;

  $numEdges = 0;


  while ((defined ($line = <INFILE>)) && 
	 ($line !~ m/^NumEdges/)) 
  {
	if ($line =~ /Edge/)
	{
	  chomp $line;
	  
	  @parsed = split(/=/, $line);    
	  @parsed = split(/,/, $parsed[1]);
	  
	  $parent = $parsed[0];
	  $child = $parsed[1];
	  $numEdges++;
	  #print "Edge: $parent -> $child\n";    
	  
	  ## Enter into table if not there
	  if (!exists($isChild{$parent})) {
		$isChild{$parent} = 0;
	  }
	  
	  $isChild{$child} = 1;
	  
	  ## Store this child under the parent
	  if (exists($rChildH->{$parent})) { push (@{ $rChildH->{$parent} }, $child); }
	  else { $rChildH->{$parent} = [ $child ]; }

	  if (exists($rChildH->{$child})) { push (@{ $rChildH->{$child} }, $parent); }
	  else { $rChildH->{$child} = [ $parent ]; }
	}
  } 

  #$$rRoot = lookForRoot(\%isChild);


  ## Error check
  @parsed = split(/=/, $line);
  if ($numEdges != $parsed[1]) { 
    print "\nERROR: Number of edges read mismatch!\n\n";
  }
}



## lookForRoot
## -----------
## Search the table for the one entry
## that is not a child. That is the root.

sub lookForRoot {
  my ($rIsChildH) = @_;
  my @nodes = keys(%$rIsChildH);
  my @roots;

  foreach my $node (@nodes) {
    if ($rIsChildH->{$node} == 0) {
      push(@roots, $node);
    }
  }
 
  if (@roots == 1) { return $roots[0]; }

  if (@roots > 1) {
    foreach my $root (@roots) { 
      print "Possible root: Node $root\n"; 
    }

    die "ARRRRRGH!\n\n";
  }
   
  else {
    die "Number of roots: <@roots> ARRRGH!\n";
  }
}






## readDataSection
## ---------------
## For each data instance:
## First line: Data [name] [id] [desc] (delimited by \s)
## Next lines: Node - [node_id] log_prob=[prob]
## 
## Goal: Seed $rObjH {id} -> @(name, desc)
##       Seed $rNodeDataH {node_id} -> @nodeData (by objID)

sub readDataSection {
  my ($rObjH, $rNodeDataH) = @_;
  my ($line, @parsed);
  my ($name, $id, $desc, $currObj);
  my ($nodeID, $prob);
  my $numObj = 0;
  
  while ((defined($line = <INFILE>)) && ($line !~ m/^DataLikelihood/)) 
  {
    chomp $line;

    ## Start of new data object
    if ($line =~ m/^Data/) {
      @parsed = split(/\s/, $line);
      
      if (@parsed < 3) { die "\nFATAL ERROR: Bad DataObject: <$line>\n\n"; }
      
      shift(@parsed);  ## the word 'Data'
      $name = shift(@parsed);
      $id = shift(@parsed);
      
      if (@parsed == 0) { $desc = "No description"; }
      else { 
		$desc = join(' ', @parsed);
      }

      ## Store the data object
      $rObjH->{$id} = [ $name, $desc ];
      #print "Object: $id, $name, $desc\n";
      
      $currObj = $id;
      $numObj++;
    }

    ## Node that the current object belongs to
    if ($line =~ m/^Node/) {
      @parsed = split(/\s/, $line);
      
      if (@parsed != 4) {
		die "\nFATAL ERROR: Bad DataObject Node: <$line>\n\n";       
      }

      $nodeID = $parsed[2];
      
      @parsed = split(/=/, $parsed[3]);
      $prob = $parsed[1];

      ## Store this node's new data object
      my @my_obj = [ $currObj, $prob ];
      #print "Node $nodeID contains Obj $currObj ($prob)\n";
      
      if (exists($rNodeDataH->{$nodeID})) {
	push (@{ $rNodeDataH->{$nodeID} }, @my_obj);
      }
      
      else {
	my @new = ( @my_obj );
	$rNodeDataH->{$nodeID} = [ @new ];
      }
    }
  }
}



## genMoreDataObj
## --------------
## Create 500 random data instances and add
## to the data structure

sub genMoreDataObj {
  my ($file, $rObjH, $rNodeDataH, $rNodeIDH) = @_;
  my @nodeIDs = keys(%$rNodeIDH);
  my $numNodes = @nodeIDs;
  my ($randNodeID, $randDesc, $randProb, $nodesAssigned);
  my $objID = 11;  ## start w/ this id
  my $numObj = 0;
  my @desc = ("hello", "hey there", "yo", "howdy");
  my $maxNumNodes = 20;
  my $stopPt;

  print "Generate $main::GEN_DATA  more data objects!\n";
  open (INFILE, ">>$file");
  srand();
  
  while ($numObj++ < $main::GEN_DATA) {
    
    ## Create random object
    $randDesc = $desc[int(rand 4)];
    my @data = [ "Gene", $randDesc ];
    $rObjH->{$objID} = @data;
    print INFILE "Data Gene$objID $objID $randDesc\n";

    ## Assign this object to random nodes
    my %assigned;
    $stopPt = int(rand $maxNumNodes);
    $nodesAssigned = 0;

    while ($nodesAssigned++ < $stopPt) {
      $randNodeID = "$nodeIDs[int(rand $numNodes)]";

      if (!exists($assigned{$randNodeID})) { ## node we haven't used
	## Store this node's new data object
	$randProb = rand();
	my @my_obj = [ $objID, $randProb ];
	print INFILE "Node - $randNodeID log_prob=$randProb\n";
      
	if (exists($rNodeDataH->{$randNodeID})) {
	  push (@{ $rNodeDataH->{$randNodeID} }, @my_obj);
	} 

	else {
	  my @new = ( @my_obj );
	  $rNodeDataH->{$randNodeID} = [ @new ];
	}

	$assigned{$randNodeID} = 1; ## mark this one as being used
      }
    }
    
    $objID++;
  }

  close INFILE;
}



## outputXMLFile
## -------------
## 1) List available data objects
## 2) Output hierarchy over those objects

sub outputXMLFile {
  my ($file, $rNodeAliasH,
      $rChildH, $rObjH, $rNodeDataH, $Root) = @_;

  open (OUTFILE, ">" . $file . "_xml");
  
  print OUTFILE "<PAH>\n";
  
  printObjList($rObjH);
  printHierarchy($rNodeAliasH, $rChildH,
		 $rNodeDataH, $root);
  
  print OUTFILE "</PAH>";
  close OUTFILE;
}



## printObjList
## ------------
## List has form:
## <Objects>
##	<Object id="[id]" name="[name]" description="[desc]">
##	</Object> 
##	.
##	.
##	.
## </Objects>

sub printObjList {
  my ($rObjH) = @_;
  my ($id, @data);

  print OUTFILE "<Objects>\n";

  foreach $id (keys %$rObjH) {
    @data = @{ $rObjH->{"$id"} };

    print OUTFILE "\t<Object id=\"$id\" name=\"$data[0]\" ",
      "description=\"$data[1]\">\n";
    print OUTFILE "\t</Object>\n";
  }
  
  print OUTFILE "</Objects>\n\n";
}



## printHierarchy
## --------------
## Starting from the root, print out the 
## hierarchy data

sub printHierarchy {
  my ($rNodeAliasH, $rChildH, 
      $rNodeDataH, $root) = @_;

  if (!defined($root)) {
    die "\nRoot node alias never specified!\n\n";
  }


#  print "Print the hierarchy!\n";
  print OUTFILE "<Hierarchy>\n";
  $main::global_kids_printed{$root} = "1";
  printTree($root, $rNodeAliasH, $rChildH, 
	    $rNodeDataH, 1);
  print OUTFILE "</Hierarchy>\n";
}



## printTree
## ---------
## Recursively print the subtree rooted
## at the given node. 
## Print children recursively
## Then print data objects belonging to this node

sub printTree {
  my ($node, $rNodeAliasH, $rChildH, 
      $rNodeDataH, $numTabs) = @_;

  printIndented($numTabs,
		"<Node id=\"$rNodeAliasH->{$node}\"".
		" name=\"$node\">");

#  print "\nNew node!\n";

  ## If the node has children
  if (exists($rChildH->{$node})) {
    ## Take care of kids
    my @children = @{ $rChildH->{$node} };
  
    foreach my $kid (@children) 
	{
	  if ($main::global_kids_printed{$kid} ne "1")
	  {
		$main::global_kids_printed{$kid} = "1";
		printTree($kid, $rNodeAliasH, $rChildH, $rNodeDataH, $numTabs + 1);    
	  }
	}
  }

  ## If the node has data
  if (exists($rNodeDataH->{$node})) {
    ## Print out data in this node
    my @data = @{ $rNodeDataH->{$node}};
  
    for (my $i=0; $i<@data; $i++) {
      my @obj = @{ $data[$i] };

#      print "<";
#      foreach my $x (@obj) { print "*$x\t"; }
#      print ">\n";


      printIndented($numTabs+1, "<Object id=\"$obj[0]\" ".
		    "probability=\"$obj[1]\">");
      printIndented($numTabs+1, "</Object>");
    
    }
  }
      
  printIndented($numTabs, "</Node>");
}



## printIndented
## -------------
## Print the given string indented
## by $numTabs

sub printIndented {
  my ($numTabs, $str) = @_;

  for (my $i=0; $i<$numTabs; $i++) {
    print OUTFILE "\t";
  }

  print OUTFILE "$str\n";
}
