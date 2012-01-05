#!/usr/bin/env	python2.6


# NETWORK DIFF
# Author: Evan Paull
# Date: Jan 2012
#
# Takes 2 network files (either 2 or 3 column tab-delimited)
# files and prints the links of the nodes that are in 
# network 1 but not the second network

from optparse import OptionParser
import sys
from sets import Set

parser = OptionParser()
(options, args) = parser.parse_args()


def usage():
	print "USAGE: networkDiff <network1.tab> <network2.tab>"
	print "	Network File: <source>\t<optional interaction>\t<target>"
	print " Prints the links of the nodes in network1 that are not in network2"
	sys.exit(1)

if len(args) != 2 or args[0] == "--help":
	usage()


def parseNet(network):

	net = {}
	for line in open(network, 'r'):
		parts = line.rstrip().split("\t")
		source = None
		target = None
		interaction = None
		if len(parts) > 2:
			source = parts[0]
			interaction = parts[1]
			target = parts[2]
		else:
			source = parts[0]
			target = parts[1]
				
		net[(source, target)] = interaction

	return net

def net2set(network):

	s = Set()
	for (source, target) in network:
		s.add(source)
		s.add(target)

	return s
		
master = parseNet(args[0])
other = parseNet(args[1])

m = net2set(master)
o = net2set(other)
nodes = m.difference(o)

for (source, target) in master:
	if source in nodes and target in nodes:
		if master[(source, target)] is not None:
			print source+"\t"+master[(source, target)]+"\t"+target
		else:
			print source+"\t"+target
	
