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

import re, sys
from optparse import OptionParser
parser = OptionParser()
parser.add_option("-r","--non_leaf",type="string",dest="non_leaf_node", action="store", help="Non leaf regex string key", default=None)
(options, args) = parser.parse_args()

abstractRE = re.compile(".*\(abstract\).*")

if options.non_leaf_node is None:
	nonLeafRE = abstractRE
else:
	nonLeafRE = re.compile(options.non_leaf_node)


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

p = re.compile(' ')
for line in sys.stdin:
	parts = line.rstrip().split("\t")
	set = parts[0]
	members = [ p.sub("_", m) for m in parts[1:] ]
	sets[p.sub("_",set)] = members


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

	print set+"\t"+"\t".join(uniq(l_members))	
