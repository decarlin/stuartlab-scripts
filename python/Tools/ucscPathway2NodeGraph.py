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

def addEdges(abs_source, abs_target, interaction, map, componentMap):
	"""
	Add the source/target interaction, break them up into
	component parts with the component map and add them to the 
	edge map
	map[ (sourceGene, interactionType) ] = targetGene
	Returns: An updated edge mapping
	"""

	# use to component map to find all the source genes
	sourceGenes = []
	if complexRE.match(abs_source):
		sourceGenes = getGenes(abs_source, componentMap, 1)
	else:
		sourceGenes.append(abs_source)

	# find target genes with the component map
	targetGenes = []
	if complexRE.match(abs_target):
		for gene in getGenes(abs_target, componentMap, 1):
			targetGenes.append(gene)
	else:
		targetGenes.append(abs_target)

	# connect these sink genes to the source gene
	for sr in sourceGenes:
		if (sr,interaction) not in map:
			map[(sr,interaction)] = []
		for target in targetGenes:
			# again, only proteins
			map[(sr,interaction)].append(target)

	return map

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
# if the interaction is a -t*, add it to the TF edge list, otherwise if -p* add it to the ppi edge list
for node in nodes:

	# complex, -t> or -t| interaction type
	type =  nodes[node]
		
	if node not in Interactions:
		continue

	for inode in Interactions[node]:

		type = Interactions[node][inode]
		if type.startswith("-t"):
			tf_edges = addEdges(node, inode, type, tf_edges, componentMap) 
		elif type.startswith("-a"):
			edges = addEdges(node, inode, type, edges, componentMap) 

interactions_out = open(options.ppi_output, 'w')
for (source, interaction) in edges:

	for sink in edges[(source, interaction)]:
		interactions_out.write(source+"\t"+sink+"\t"+interaction+"\n")

interactions_out.close()
			
tf_out = open(options.tf_output, 'w')
for (source, interaction) in tf_edges:

	for sink in tf_edges[(source, interaction)]:
		tf_out.write(source+"\t"+sink+"\t"+interaction+"\n")

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

# go over every interaction: 
# map connections onto proteins
for source in Interactions:
	targets = Interactions[source]

	# use to component map to find all the source genes
	sourceGenes = None
	if complexRE.match(source):
		sourceGenes = getGenes(source, componentMap, 1)
	else:
		sourceGenes = [ source ]

	# find target genes with the component map
	targetGenes = []
	for target in targets:
		if complexRE.match(target):
			for gene in getGenes(target, componentMap, 1):
				targetGenes.append(gene)
		else:
			targetGenes.append(gene)

	# connect these sink genes to the source gene
	for sr in sourceGenes:

		# only proteins here
		if sr not in edges:
			continue

		for target in targetGenes:
			# again, only proteins
			if target in edges:
				if sr == target:
					continue
				edges[sr][target] = None



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
