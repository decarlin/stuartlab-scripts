#!/usr/local/bin/python2.6

# FOLLOW.PY
# Author: Evan Paull
# Date: 1-29-12
# takes a sets file from expand.pl and follows interactions on non-leaf nodes
# to get an expanded set. Must specify a regex key for non-leaf nodes on input 
# (default is "(abstract)")
#
# The current use for this is to find the transitive neighbors of abstract 
# concepts in the superpathway

import re, sys, mPathway
from optparse import OptionParser
parser = OptionParser()
parser.add_option("-r","--non_leaf",type="string",dest="non_leaf_node", action="store", help="Non leaf regex string key", default=None)
parser.add_option("-p","--pathway_file",type="string",dest="pathway_file", action="store", help="superpathway file")
(options, args) = parser.parse_args()

rev_nodes, revInteractions = mPathway.rPathway(options.pathway_file, reverse = True, retProteins = False)
# maps complex strings to the components in each
componentMap = mPathway.getComponentMap(rev_nodes, revInteractions)

space2under = re.compile(' ')
under2space = re.compile('_')

abstractRE = re.compile(".*\(abstract\).*")
complexRE = re.compile(".*\((complex|family)\).*")

if options.non_leaf_node is None:
	nonLeafRE = abstractRE
else:
	nonLeafRE = re.compile(options.non_leaf_node)

# get the constituents of a complex
def getGenes(complex_str, componentMap, depth):
	all_genes = []

	complex_str = under2space.sub(" ", complex_str)
	# give up
	if complex_str not in componentMap:
		return []

	for component in componentMap[complex_str]:
		if complexRE.match(component):
			if component in componentMap and depth < 4:
				genes = getGenes(component, componentMap, depth+1)
				for gene in genes:
					all_genes.append(gene)
		else:
			all_genes.append(component)

	all_genes = [ space2under.sub("_", g) for g in all_genes ]
	return all_genes

def parseCM(cm):

	hash = {}
	for line in open(cm, 'r'):
		parts = line.rstrip().split("\t")
		c = parts[0]
		constituents = parts[1:]
		hash[c] = constituents

	return hash

def uniq(seq):  
    # order preserving 
    checked = [] 
    for e in seq: 
        if e not in checked: 
            checked.append(e) 
    return checked

def getLeaves(allSets, set, depth):

	if depth > 5 or (set not in allSets):
		return [ set ]

	leaves = []	
	children = allSets[set]
	for l in children:
		if nonLeafRE.match(l):
			for x in getLeaves(allSets, l, depth+1):
				leaves.append(x)	
		else:
			leaves.append(l)

	return leaves

sets = {}

for line in sys.stdin:
	parts = line.rstrip().split("\t")
	set = parts[0]
	members = [ space2under.sub("_", m) for m in parts[1:] ]
	sets[space2under.sub("_",set)] = members


# expand complexes to constituent (gene and abstract) parts
for set in sets:

	members = sets[set]
	l_members = []

	for m in members:
		if complexRE.match(m):
			for l in getGenes(m, componentMap, 1):
				l_members.append(l)
		else:
			l_members.append(m)

	sets[set] = uniq(l_members)

# expand abstract sets first by following...
for set in sets:

	if not nonLeafRE.match(set):
		continue
	
	members = sets[set]
	l_members = []

	for m in members:
		if nonLeafRE.match(m):
			for l in getLeaves(sets, m, 1):
				l_members.append(l)
		else:
			l_members.append(m)

	sets[set] = uniq(l_members)

# print out the sets
for set in sets:
	print under2space.sub(" ", set)+"\t"+"\t".join([ under2space.sub(" ", m) for m in sets[set] ])
