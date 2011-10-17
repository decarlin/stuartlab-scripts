#!/usr/local/bin/python2.6

import mPathway, sys, re, collections, itertools

from optparse import OptionParser

parser = OptionParser()
parser.add_option("-p","--pathway_file",type="string",dest="pathway_file", action="store", help="UCSC Pathway File")
parser.add_option("--tf_output",type="string",dest="tf_output", action="store", help="Output file for Transcription Factor links")
parser.add_option("--c_output",type="string",dest="component_output", action="store", help="Output file for Component Map")
parser.add_option("--ppi_output",type="string",dest="ppi_output", action="store", help="Output file for PPI links")
parser.add_option("--flattened",type="string",dest="flattened", action="store", help="Join genes with all pathway links for complexes and families they belong to. Print that network with just proteins")
(options, args) = parser.parse_args()


# nodes:
#	name -> type
# interactions:
#	name -> interacting nodes
nodes, Interactions, Proteins = mPathway.rPathway(options.pathway_file, reverse = False, retProteins = True)

nodes, revInteractions = mPathway.rPathway(options.pathway_file, reverse = True, retProteins = False)
# maps complex strings to the components in each
componentMap = mPathway.getComponentMap(nodes, revInteractions)

complexRE = re.compile(".*\((complex|family)\).*")

# get the constituents of a complex
def getGenes(complex_str, componentMap, depth):
	all_genes = []

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

	return all_genes


# print out a 2-column interactions file of simple PPIs
# protein -> protein
edges = {}
tf_edges = {}

# members in a complex get a different edge weight
# parse past the protein and complex definitions
complex_edges = collections.defaultdict(list)
for line in open(options.pathway_file, 'r'):
	type, name = line.rstrip().split("\t")
	if type == "protein":
		continue
	elif type == "complex":
		proteins = getGenes(name, componentMap, 1)
		for combo in itertools.combinations(proteins, 2):
			complex_edges[combo[0]].append(combo[1])
	else:
		break	
			

# for each node, find all interactions, and use the component map to refine them to genes
# if the interaction is a -t>, add it to the TF edge list, otherwise add it to the ppi edge list
for node in nodes:

	# complex, etc
	type =  nodes[node]
		
	# for each protein, add all interactions to corresponding elements
	edges[node] = [] 
	tf_edges[node] = [] 

	if node not in Interactions:
		continue

	for inode in Interactions[node]:

		type = Interactions[node][inode]
		if type.startswith("-t"):
			tf_edges[node].append(gene)	
			continue

		if complexRE.match(inode):
			genes = getGenes(inode, componentMap, 1)
			for gene in genes:
				edges[node].append(gene)	

interactions_out = open(options.ppi_output, 'w')
for source in edges:

	for sink in edges[source]:
		interactions_out.write(source+"\t"+sink+"\n")

interactions_out.close()
			
tf_out = open(options.tf_output, 'w')
for source in tf_edges:

	for sink in tf_edges[source]:
		tf_out.write(source+"\t"+sink+"\n")

tf_out.close()

c_out = open(options.component_output, 'w')
for component in componentMap:
	c_out.write(component+"\t"+" ".join(componentMap[component])+"\n")
c_out.close()

# protein edges

edges = {}
for p in Proteins:

	# build edges
	edges[p] = {}

	if not p in Interactions:
		continue

	# add direct interactions
	for inode in Interactions[p]:
		genes = None
		if complexRE.match(inode):
			genes = getGenes(inode, componentMap, 1)
		else:
			genes = [ inode ]

		for gene in genes:
			if p == gene:
				continue
			edges[p][gene] = None

# go over every complex: for each gene
for component in componentMap:
	source_genes = getGenes(component, componentMap, 1)
	sink_genes = {}

	for node in componentMap[component]:
		genes = None
		if complexRE.match(inode):
			genes = getGenes(node, componentMap, 1)
		else:
			genes = [ node ]

		# connect these sink genes to the source gene
		for sr in source_genes:

			# only proteins here
			if sr not in edges:
				continue

			for sink in genes:
				# again, only proteins
				if sink in edges:
					if sr == sink:
						continue
					edges[sr][sink] = None

# print it out
flattened_out = open(options.flattened, 'w')
for source in edges:
	for sink in sorted(edges[source]):
		flattened_out.write(source+"\t"+sink+"\n")
flattened_out.close()

#for source in complex_edges:
#
#	for sink in complex_edges[source]:
#		print source+"\t"+sink
#

# print a simple TF interactions file
