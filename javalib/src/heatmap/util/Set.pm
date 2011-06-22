#!/usr/bin/perl -w
#Author:	Evan Paull (epaull@soe.ucsc.edu)
#Create Date:	6.16.2010

use strict;
use warnings;
# JSON object serialization
use JSON -convert_blessed_universally;

our $TRUE = 1;
our $FALSE = 0;

package Set;

##
## Static Methods: parseSetLines, sortByName
##

sub new
{
	my $class = shift;
	# hash ref

	# trick to use the new method of an existing object to instantiate
	if (ref($class) eq 'Set') { 
		$class = 'Set';
	}

	my $self;
	if (@_ >= 2) {
		my $name = shift;
		my $active = shift;
		my $metadata = shift;
		my $elements = shift;

		$self = {
			'_name' 	=> $name,
			# boolean 1=yes, 0=no 
			'_active'	=> $active,
	 		'_metadata' 	=> $metadata,
			#'_metadata' 	=> { 'key2 => 'value1',
			# 		     'key2 => 'value2
			'_elements'	=> $elements,
			# '_elements'	=> { 'name' 	=>  $setObj1,
			#		     'name2' 	=>  $setObj2
			'_delim'	=> '^',
		};
	} elsif (@_ == 1) {
		
		my $json_text_or_hash = shift;
		if (ref($json_text_or_hash) eq 'HASH') {
			$self = $json_text_or_hash;
		} else {
			my $json = JSON->new->utf8;
			$self = $json->decode($json_text_or_hash);
		}

		# self, and all it's elements are just hash refs now
		# -- we need to recursively bless each into being a 'Set' object
		foreach (keys %{$self->{'_elements'}}) {
			my $element_name = $_;
			#next unless ($element_name =~ /:/);
			# element is just a gene name
			next unless (ref($self->{'_elements'}->{$element_name}) eq 'HASH');

			my $obj_type;
			if (exists $self->{'_elements'}->{$element_name}->{'type'}) {
				$obj_type = $self->{'_elements'}->{$element_name}->{'type'};
			}

			# Entity objects may be present rather than just plain keyvalues -- these
			# are also a valid way of representing a Set's elements, and must be passed
			# to the appropriate constructor
			if ($obj_type eq 'Entity') { 
				$self->{'_elements'}->{$element_name} = Entity->new($self->{'_elements'}->{$element_name});
			} else {
				# element is another set -- create it
				$self->{'_elements'}->{$element_name} = Set->new($self->{'_elements'}->{$element_name});
			}
		}

	} elsif (!@_) {
		die "Set::new method called without arguments!";
	}

	bless $self, $class;
	return $self;
}

sub convert_entities
{
	my $self = shift;

	foreach ($self->get_element_names) {

		my $name = $_;
	 	my $element = $self->get_element($name);
	     
	  	if (ref($element) eq 'Set') {
			$element->convert_entities;
	  	} elsif (ref($element) eq 'Entity') {
			$self->set_element($name, $element->get_membership_value);
		}
	}
}

# ensure uniqe elements by appending the keyspace source and organism
sub to_json_heatmap_str
{
	my $self = shift;

	my $organism = $self->get_organism || "none";
	my $source = $self->get_keyspace_source || "none";

	my $new_set = Set->new($self->get_name, 1, {'source' => $source, 'organism' => $organism, 'type' => "set"}, {});

	foreach ($self->get_element_names) {

		my $name = $_;
	 	my $element = $self->get_element($name);
	     
		my $uniq_name = $name."-".$organism."-".$source;

	  	if (ref($element) eq 'Entity') {
			my $uniq_name = $name."-".$organism."-".$source;
			$new_set->set_element($uniq_name, $element->get_membership_value);
		} else {
			$new_set->set_element($uniq_name, $element);
		}
	}

	return $new_set;
}

sub serialize
{
	my $self = shift;
	
	my $json = JSON->new->utf8;
	$json = $json->convert_blessed([1]);
	my $json_text = $json->encode($self);

	return $json_text;
}

sub get_name
{
	my $self = shift;
	return $self->{'_name'};
}

sub get_type
{
	my $self = shift;
	# should be either meta or set
	return $self->get_metadata_value('type');
}

sub get_id
{
	my $self = shift;
	my $id = $self->get_metadata_value('id');

	return ($id =~ /\d+/) ? $id : undef;	
}

sub pare_inactive_leaves
{
	my $self = shift;

	my $type = $self->get_metadata_value('type');
	my $active = $self->is_active;

	if ($type eq 'set' && $active == 1) {
		return 1;
	} elsif ($type eq 'set' && $active == 0) {
		return 0;
	} else {
		my $one_active = 0;
		foreach (keys %{$self->{'_elements'}}) {
			my $name = $_;
			my $element = $self->get_element($name);
			if ($element->pare_inactive_leaves > 0) {
				$one_active = 1;
			} else {
				# clean inactive subtrees
				$self->delete_element($name);
			}
		}
		return $one_active;
	}
}

sub get_source
{
	my $self = shift;
	return $self->get_metadata_value('source');
}

sub set_source
{
	my $self = shift;
	my $source = shift;

	$self->set_metadata_value('source', $source);
}

sub get_keyspace_source
{
	my $self = shift;

	return $self->get_metadata_value('keyspace_source');
}

sub set_keyspace_source
{
	my $self = shift;
	my $keysp_source = shift;

	$self->set_metadata_value('keyspace_source', $keysp_source);
}

sub get_organism
{
	my $self = shift;

	return $self->get_metadata_value('organism');
}

sub set_organism
{
	my $self = shift;
	my $organism = shift;

	$self->set_metadata_value('organism', $organism);
}

sub is_active
{
	my $self = shift;
	return $self->{'_active'};
}

sub has_db_id
{
	my $self = shift;
	if ($self->get_metadata_value('id') =~ /\d\d+/) {
		return $TRUE;
	}
	return $FALSE;
}

sub set_active
{
	my $self = shift;
	$self->{'_active'} = 1;
}

sub set_inactive
{
	my $self = shift;
	$self->{'_active'} = 0;
}

sub get_ex_id
{
	my $self = shift;
	
	if (exists $self->{'_metadata'}->{'ex_id'}) {
		return $self->get_metadata_value('ex_id');
	} else {
		return $self->get_name;
	}
}

sub has_element
{
	my $self = shift;
	my $element_name = shift;

	if (exists $self->{'_elements'}->{$element_name}) { 
		if ($self->{'_elements'}->{$element_name} eq "") {
			# no membership value 
			return 1;
		} elsif (ref($self->{'_elements'}->{$element_name}) eq "Entity") {
			# membership value...
			return $self->{'_elements'}->{$element_name}->get_membership_value;
		} elsif ($self->{'_elements'}->{$element_name} =~ /.*\d+/) {
			return $self->{'_elements'}->{$element_name};
		}
	}

	return 0;
}

sub get_element
{
	my $self = shift;
	my $element_name = shift;

	unless (ref($self->{'_elements'}) eq 'HASH') { return ""; }
	unless (exists $self->{'_elements'}->{$element_name}) { return ""; }
	return $self->{'_elements'}->{$element_name};
}

sub get_elements
{
	my $self = shift;

	my @elements;
	foreach ($self->get_element_names) {
		push @elements, $self->get_element($_);
	}

	return @elements;
}

sub set_element
{
	my $self = shift;
	my $element_name = shift;
	my $element = shift;

	$self->{'_elements'}->{$element_name} = $element;
}

sub set_element_inactive
{
	my $self = shift;
	my $element_name = shift;

	$self->{'_elements'}->{$element_name}->{'_active'} = 0;
}

sub delete_element
{
	my $self = shift;
	my $element_name = shift;

	if (exists($self->{'_elements'}->{$element_name})) { 
		delete($self->{'_elements'}->{$element_name});
	}
}

sub get_element_names
{
	my $self = shift;

	if (ref($self->{'_elements'}) eq 'HASH') {
		return (keys %{$self->{'_elements'}});	
	} else {
		return "";
	}
}

sub get_metadata_names
{
	my $self = shift;

	return (keys %{$self->{'_metadata'}});	
}

sub get_metadata_value
{
	my $self = shift;
	my $key = shift;

	return $self->{'_metadata'}->{$key};
}

sub set_metadata_value
{
	my $self = shift;
	my $key = shift;
	my $value = shift;

	$self->{'_metadata'}->{$key} = $value;
}


#
# Find a place where they differ, then add the second tree's subsets to the first 
# tree's subsets
#
sub mergeTree($)
{
	my $self = shift;
	my $tree2 = shift;

	unless (ref($self) eq 'Set' && ref($tree2) eq 'Set') {
		return $FALSE;
	}
	#different head nodes always means we can't merge
	unless ($self->get_name eq $tree2->get_name) {
		return $FALSE;
	}

	# trick: if one is active, they should both be
	# set as active as part of the merge
	if ( ($self->is_active == 0) || ($tree2->is_active == 1) ) {
		$self->set_active;
	}

	my @children_of_1 = $self->get_element_names;
	my @children_of_2 = $tree2->get_element_names;

	my @children_only_in_tree_2;


	foreach (@children_of_2)
	{
		my $child = $_;
		my $found = $FALSE;
		
		foreach (@children_of_1) {
			if ($child eq $_) {
				$found = $TRUE;	
				last;
			}
		}

		# this is in tree 2, but not in tree 1, so add the element to tree 1	
		my $element = $tree2->get_element($child);
		if ($found == $FALSE) {
			$self->set_element($child, $element); 
		} else {
		# otherwise they both have the same node -- merge the subnodes
			my $subtree = $self->get_element($child);

			# these must both be sets for the merge to be meaningful
			next unless (ref($subtree) eq 'Set');
			next unless (ref($element) eq 'Set');

			$subtree->mergeTree($element);	
		}
	}

	return $TRUE;
}

# Disjoint trees
# instance method
sub mergeTrees
{
	my $self = shift;
	my @trees = shift;

	foreach (@trees) {
		my $tree = $_;
		if ($self->mergeTree($tree) > 0) {
			# stop at the first successful merge: 
			# @trees are mutually disjoint, so 
			# if it matches one, it must not match any other
			# tree of the collection
			return $tree->get_name;
		}
	}

	return $FALSE;
}

##
## REQUIRE: Sets in each collection are mutually disjoint!!
##
## Static method; satisfies transitivity among merges, 
## assuming that both sets of sets are disjoint 
##
## Given collection 1 of mutually disjoint trees, and a
## collection 2 of mutually disjoint trees, we can assume
## that (because the top nodes must match to have an overlap)
## if a given tree -A- from collection 1 does match another
## tree from collection 2 -B-, then it must not match any other
## tree from collection 2, from the mutual disjoint property.
## At that point, we can terminate the loop
sub mergeDisjointCollections
{
	my $collection1REF = shift;
	my $collection2REF = shift;

	my @collection2 = @{$collection2REF};

	my @merged_trees;
	foreach (@{$collection1REF}) {

		my $tree = $_;
		my $retval = $tree->mergeTrees(@collection2);
	
		# no match
		next if ($retval eq $FALSE);

		# remove whichever tree of collection 2 matched -- since collections are 
		# disjoint, it won't match any other trees in collection 2
		@collection2 = removeTreeFromCollection($retval, @collection2);
	}

	# whatever hasn't been removed from collection 2 has had no match, so 
	# we can remove it now
	@merged_trees = (@{$collection1REF}, @collection2);
	return @merged_trees;
}

sub removeTreeFromCollection
{
	my $nameToRemove = shift;
	my @collection = @_;

	my @pared_collection;
	foreach (@collection) {
		unless ($_->get_name eq $nameToRemove) {
		  push @pared_collection, $_;
		}
	}

	return @pared_collection;
}

sub mergeCheckbox_Remove
{
	my $self = shift;
	my $checkboxHash = shift;

	foreach ($self->get_element_names) {
		my $name = $_;
		my $element = $self->get_element($name);

		if (exists $checkboxHash->{$name}) {
		  if (ref($element) eq 'Set') {
			$element->mergeCheckbox_Remove($checkboxHash);
		  }
		} else {
		  #delete it
		  if (ref($element) eq 'Set') {
		  	$self->delete_element($name);
		  } 
			# don't delete scalar elements
		}
	}
}

sub mergeCheckbox_Inactivate
{
	my $self = shift;
	my $checkboxHash = shift;

	foreach ($self->get_element_names) {
		my $name = $_;
	 	my $element = $self->get_element($name);
	     
		unless (exists $checkboxHash->{$name}) {
	  	  if (ref($element) eq 'Set') {
			$self->set_element_inactive($name);
		  } else {
			#how to inactivate a gene???
		  } 
		}
	  	if (ref($element) eq 'Set') {
			$element->mergeCheckbox_Inactivate($checkboxHash);
	  	}
	}
}

sub mergeCheckbox_Simple
{
	my $self = shift;
	my $checkboxHash = shift;

	if (exists $checkboxHash->{$self->get_name}) {
		$self->set_active;
	} else {
		$self->set_inactive;
	}

	foreach ($self->get_element_names) {
		my $name = $_;
	 	my $element = $self->get_element($name);
	     
	  	if (ref($element) eq 'Set') {
			$element->mergeCheckbox_Simple($checkboxHash);
	  	}
	}
}

sub convertDisplay
{
	my $self = shift;

	if ($self->get_metadata_value('type') eq 'meta') {
		$self->set_metadata_value('type', 'meta_display');	
	} else {
		$self->set_metadata_value('type', 'set_display');	
		return;
	}
	
	foreach ($self->get_element_names) {
		my $name = $_;
	 	my $element = $self->get_element($name);
	     
	  	if (ref($element) eq 'Set') {
			$element->convertDisplay();
	  	}
	}
}


sub getLeafNodes()
{
	my $self = shift;	

	my @leafnodes;	

	my @names = $self->get_element_names;
	if ($#names == -1) { push @leafnodes, $self; }

	my $set_isa_leaf = $TRUE;
	foreach (@names) {
		my $name = $_;
	 	my $element = $self->get_element($name);

	  	next unless (ref($element) eq 'Set');

		$set_isa_leaf = $FALSE;

		my $isleaf = $TRUE;
		foreach ($element->get_element_names) {
			my $subelement = $element->get_element($_);
			if (ref($subelement) eq 'Set') {
				my @subleaves = $subelement->getLeafNodes;
				push @leafnodes, @subleaves;
				$isleaf = $FALSE;
			}
		}

		if ($isleaf == $TRUE) { 
			push @leafnodes, $element; 
		}
	}

	if ($set_isa_leaf == $TRUE) {
		push @leafnodes, $self;
	}

	return @leafnodes;
}

sub insertDB
{
	my $self = shift;
	my $db = shift;
	# hash ref to entity objects
	my $entities = shift;
	my $error_ref = shift;

	my $type = $self->get_type;

	unless (ref($db) eq 'BeastDB') {
		$$error_ref = "Bad BeastDB Handle";
		return $FALSE;
	}


	if ($type eq 'meta') {
		
		my $meta_id;
		unless ( ($meta_id = $db->existsMeta($self->get_ex_id)) > 0) {
			$meta_id = $db->insertMeta($self->get_ex_id, $self->get_metadata_value('name'));
			unless ($meta_id =~ /\d+/) {
				$$error_ref = "Can't insert Meta";
				return $FALSE;
			}
			$$error_ref = "Added Meta ".$self->get_name." to DB";
		} else {
			$$error_ref = "Meta ".$self->get_name." already exists";
		}

		$self->set_metadata_value('id', $meta_id);
		return $TRUE;
	}

	unless ($type eq 'set') {
		$$error_ref = "Not type 'set' or 'meta'";
	}

	my $source = $self->get_metadata_value('source');
	unless ($source) {
		$$error_ref = "No Source Metadata";
		return $FALSE;
	}

	my $set_internal_id = $db->existsSet($self->get_ex_id);


	if ($set_internal_id > 0) {
		$$error_ref = "Set Already In DB";
		# already in DB, do nothing...
	} else {
		$set_internal_id = $db->insertSet($self->get_name, $self->get_ex_id);
		unless ($set_internal_id =~ /\d+/) { 
			$$error_ref = "Failed to Insert Set ".$self->get_name;
			return $FALSE;	
		} else {
			$$error_ref .= "Added Set ".$self->get_name." To DB";
		}

	
		foreach my $meta ($self->get_metadata_names) {

			next if ($meta =~ /id|ex_id/);

			my $sql = "INSERT INTO sets_info (sets_id, name, value) VALUES ('";
			$sql .= "$set_internal_id"."', '"."$meta"."', '".$self->get_metadata_value($meta)."');";

			my $meta_id = $db->insertSQL($sql);
			unless ($meta_id =~ /\d+/) {
				$$error_ref .= "Failed to Add Metadata\n";
				return $FALSE;
			}		
		}

		foreach my $element_name ($self->get_element_names) {

			# the entities hash is optional: otherwise we'll have to 
			# query the DB for the entity ID
			my $entity_id;
			if ( !($entities eq "") && ref($entities) eq 'HASH') {
				if (exists $entities->{$element_name}) {
					$entity_id = $entities->{$element_name}->get_id;
				} else {
					# fallback plan
					$entity_id = $db->getEntityIDFromExternalID($element_name);	
					$$error_ref .= 
				"Entity not Elements Hash Ref not set for obj $element_name, set:".$self->get_name." !\n";
					print $$error_ref;
					next;
				}
			} else {
				$entity_id = $db->getEntityIDFromExternalID($element_name);	
			}

			unless ($entity_id && $entity_id =~ /\d+/) {
				$$error_ref .= "Entity not in DB or ID not set for obj $element_name!\n";
				next;
			}

			#if ($db->existsSetEntityRel($set_internal_id, $entity_id) > 0) {
			#	$$error_ref .= "entity already in DB".$element_name."\n";
			#} else {
				my $element_value = $self->get_element($element_name);
				if ($element_value eq "") {
					$element_value = "NULL";	
				}
				$db->insertSetEntityRel($set_internal_id, $entity_id, $element_value);
			#}
		}
	}
					
	$self->set_metadata_value('id', $set_internal_id);
}

# simple tab delineated string
sub toString
{
	my $self = shift;

	my $str = $self->get_name;

	my @names = $self->get_element_names;	
	
	foreach my $i (0 .. (scalar(@names) - 1) ) {
		my $element = $self->get_element($names[$i]);
		if (ref($element) eq 'Set') {
			$str .= "\t".$element->get_name;
		# entity objects store the ex_id -- use this for comparison
		} elsif (ref($element) eq 'Entity') {
			# ex_id plus a keyspace is sufficient to produce a unique ID
			$str .= "\t".$element->get_ex_id;
		} else {
			$str .= "\t".$names[$i];
		}
	}

	return $str;	
}

sub parseSetLines
{
	my $errstr = shift;
	my @lines = @_;

	my @sets;

	my $count = 1;
	for my $line (@lines) 
	{
		chomp($line);
		# for any windows files: chomp doesn't strip \r's
		$line =~ s/\r//g;

		#fail 1
		unless ($line =~ /\S+\t\S+/) {
			$$errstr = "$count Can't parse line: $line\n no tabs \n";
			return 0;
		}

		my @components = split(/\t/, $line);

		#unless ($line =~ /\^/) {
		#	$$errstr = "$count Can't parse line: $line\n no '^' (carat)\n";
		#	return 0;
		#}

		my @meta_components;
		my $name;
		($name, @meta_components) = split(/\^/, $components[0]);
		
		if ($name =~ /=/) {
			$$errstr = "$count Can't parse line: $line\n name has equals sign \n";
			return 0;
		}

		my $metadata = {};
		foreach (@meta_components) {
			if ($_ =~ /(.*)=(.*)/) {
				  $metadata->{$1} = $2;
			} else {
				$$errstr = "$count Can't parse line: $line\n metadata has no equals sign \n";
				return 0;
			} 
		}
		
		Math::BigFloat->accuracy(3);
		my $elements = {};
		for my $i (1 .. $#components) 
		{
			if ($components[$i] =~ /.*\s+.*/) {
				die "can't parse: $line! part $components[$i] has whitespace \n";
			}

			if ($components[$i] =~ /(\S+)\^(-?[\d\.]+)/) {

				my $el = $1;
				my $float = Math::BigFloat->new($2);
				# pare down the precision to 5 dec	
				my $numeric = $float->bstr();
				chomp($numeric);
				$elements->{$el} = $numeric;
			} else {
				$elements->{$components[$i]} = "";	
			}
		}

		my $set = Set->new($name, "1", $metadata, $elements);
		# set meta type to 'set' 
		$set->set_metadata_value('type', 'set');

		# generate a 'fake' local id that allows us to identify this
		# as a local variable
		my $id = int(rand(1000000));
		$set->set_metadata_value('id', 'local_'.$id);

		push @sets, $set;
		$count++;
	}

	return @sets;
}

# 
# Generate Sets Union:
# 
# INPUT: Takes a set of leaf sets, all which must be terminal -- i.e. their
# elements are either key/value pairs, or Entity objects, and returns
# the set that is the union
sub generateSetsUnion
{
	my $name = shift;
	my @sets = @_;

	my $keyspace_source;
	my $keyspace_organism;
	my $source;

	my $elements = {};
	foreach my $set (@sets) {

		# set and check the metadata
		if ($keyspace_source) {
			unless ($keyspace_source eq $set->get_keyspace_source) {
				print "Error: Sets union not possible if sets don't have the same keyspace source!";
				return 0;
			}
		} else {
			$keyspace_source = $set->get_keyspace_source;
		}

		if ($keyspace_organism) {
			unless ($keyspace_organism eq $set->get_organism) {
				print "Error: Sets union not possible if sets don't have the same keyspace organism!";
				return 0;
			}
		} else {
			$keyspace_organism = $set->get_organism;
		}

		if ($source) {
			unless ($source eq $set->get_source) {
				print "Error: Sets union not possible if sets don't have the same source!";
				return 0;
			}
		} else {
			$source = $set->get_source;
		}

		foreach my $name ($set->get_element_names) {
			unless (exists $elements->{$name}) { 
				if (ref($set->get_element($name)) eq 'Set') {
					print "Error: not a leaf set $name, for union";
					return 0;
				}
				$elements->{$name} = $set->get_element($name);
			}
		}
	}

	# we have to generate a local id for this set, since it won't be in the database
	my $id = int(rand(1000000));
	return Set->new($name, "1",  
		{'keyspace_source' => $keyspace_source, 'organism' => $keyspace_organism,
			'source' => $source, 'type' => 'set', 'id' => 'local_'.$id }, $elements);
}

# 
# Generate Sets Intersection:
# 
# INPUT: Takes a set of leaf sets, all which must be terminal -- i.e. their
# elements are either key/value pairs, or Entity objects, and returns the set that is 
# the intersection
sub generateSetsIntersection
{
	my $name = shift;
	my @sets = @_;

	my $keyspace_source;
	my $keyspace_organism;
	my $source;

	# add the first sets elements
	my $elements = $sets[0]->{'_elements'};

	#  we don't have to check that these are the same -- they always
	# are for any intersection!
	$keyspace_source = $sets[0]->get_keyspace_source;
	$keyspace_organism = $sets[0]->get_organism;
	$source = $sets[0]->get_source;

	foreach my $set (@sets) {

		# remove any elements that aren't contained in this set
		foreach my $name (keys %$elements) {
			if ($set->has_element($name) == 0) {
				delete $elements->{$name};
			}
		}
	}

	if (scalar(keys %$elements) == 0) {
		print "Chosen sets have no intersection!";
		return 0;
	}

	# we have to generate a local id for this set, since it won't be in the database
	my $id = int(rand(1000000));
	return Set->new($name, "1",  
		{'keyspace_source' => $keyspace_source, 'organism' => $keyspace_organism,
			'source' => $source, 'type' => 'set', 'id' => 'local_'.$id }, 
		$elements);
}

# returns only the names of the elements
sub generateSetsUnionSummary
{
	my @sets = @_;

	my $elements = {};
	foreach my $set (@sets) {
		foreach my $name ($set->get_element_names) {
			$elements->{$name} = 1;
		}
	}

	return keys %$elements;
}

1;
