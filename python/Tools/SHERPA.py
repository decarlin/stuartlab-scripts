#!/usr/bin/env python2.7
import os, sys

from optparse import OptionParser
from os import path,mkdir
parser = OptionParser()
parser.add_option("-d","--depth",dest="depth",action="store",default="7",help="Search depth (default 7)")
parser.add_option("-n","--network",dest="network",action="store",default=None,help="Base Network in UCSC Pathway Format")
parser.add_option("-o","--output_directory",dest="od",action="store",default="SearchDFS_Result",help="Output Directory for Networks and Report")
parser.add_option("-u","--upstream_genes",dest="up",action="store",default=None,help="Upstream (Cell Surface) Gene Set")
parser.add_option("-s","--signaling_genes",dest="signaling",action="store",default=None,help="Optional Signaling genes: must be used to connect paths if present")
parser.add_option("-d","--downstream_genes",dest="down",action="store",default=None,help="Downstream (Cell Nucleus) Gene Set")
parser.add_option("-o","--output_directory",dest="od",action="store",default="SHERPA_RESULT",help="Output Directory for Networks and Report")
(opts, args) = parser.parse_args()

def parseNet(network):

	net = {}
	for line in open(network, 'r'):

		parts = line.rstrip().split("\t")
		source = parts[0]
		interaction = parts[2]
		target = parts[1]

		if source not in net:
			net[source] = set()

		net[source].add((interaction, target))

	return net

def parseLST(file):
	nodes = {}
	for line in open(file, 'r'):
		parts = line.rstrip().split("\t")
		nodes[parts[0]] = 1

	return set(nodes.keys())


def searchDFS(source, discovered, linker_nodes, intermediate_set, intermediate_traversed_status, target_set, net, depth):

	if depth == 0:
		return

	if source not in net:
		return

	for (interaction, target) in net[source]:

		# we hit a target that has a matching action/signal from the original source
		if (target in target_set) and intermediate_traversed_status:

			for (s,i,t) in linker_nodes:
				discovered.add((s,i,t))
			discovered.add((source, interaction, target))
			linker_nodes = set()
			new_linkers = set()
			# and keep going

		# search the target, but with any previous linkers	
		else:

			# if we've found an intermediate/signaling node, set the status and continue the search
			if target in intermediate_set:
				intermediate_traversed_status = True

			# add these linkers to the stack
			new_linkers = set()
			new_linkers.add((source, interaction, target))
			new_linkers = new_linkers.union(linker_nodes)	


		# add this link and keep searching from the target
		searchDFS(target, discovered, new_linkers, intermediate_set, intermediate_traversed_status, target_set, net, depth-1)

network = parseNet(opts.network)
source_set = parseLST(opts.up)
target_set = parseLST(opts.down)

filtered_edges = set()
if opts.signaling is None:
	for source in source_set:
		# no intermediate set of genes in this case
		searchDFS(source, filtered_edges, set(), set(), True, target_set, network, int(opts.depth))
else:
	# connect source to signaling:
	signaling_set = parseLST(opts.signaling)
	status = False
	for source in source_set:
		# connect each source to the intermediate layer: if it doesn't connect don't include the source
		searchDFS(source, filtered_edges, set(), signaling_set, status, target_set, network, int(opts.depth)-2)

gene_list = set()
for (e1,i,e2) in filtered_edges:
	gene_list.add(e1)
	gene_list.add(e2)

out_dir = opts.od
if not os.path.exists(out_dir):
	os.mkdir(out_dir)
out_network = None
try:
	out_network = open(out_dir+"/search_result.sif", 'w')
except:
	print "Error: Can't Create Directory for Report"

for edge in filtered_edges:
	out_network.write("\t".join(edge)+"\n")
out_network.close()

out_report = open(out_dir+"/report.txt",'w')
ig = source_set.intersection(gene_list)
i = str(len(ig))
out_report.write(i+" of "+str(len(source_set))+" source genes captured: "+"\t".join(ig)+"\n")
ig = target_set.intersection(gene_list)
i = str(len(ig))
out_report.write(i+" of "+str(len(target_set))+" target genes captured: "+"\t".join(ig)+"\n")
if opts.signaling is not None:
	ig = signaling_set.intersection(gene_list)
	i = str(len(ig))
	out_report.write(i+" of "+str(len(signaling_set))+" signaling genes captured: "+"\t".join(ig)+"\n")
out_report.close()
