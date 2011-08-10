#!/usr/bin/python

import mPathway, sys, re


from optparse import OptionParser
parser = OptionParser()
parser.add_option("-p","--pathway_file",type="string",dest="pathway_file", action="store", help="UCSC Pathway File")
parser.add_option("--tf_output",type="string",dest="tf_output", action="store", help="Output file for Transcription Factor links")
parser.add_option("--ppi_output",type="string",dest="ppi_output", action="store", help="Output file for PPI links")
(options, args) = parser.parse_args()


# nodes:
#	name -> type
# interactions:
#	name -> interacting nodes
nodes, Interactions = mPathway.rPathway(options.pathway_file, reverse = False, retProteins = False)

nodes, revInteractions = mPathway.rPathway(options.pathway_file, reverse = True, retProteins = False)
# maps complex strings to the components in each
componentMap = mPathway.getComponentMap(nodes, revInteractions)

complexRE = re.compile(".*\(complex\).*")

# get the constituents of a complex
def getGenes(complex_str, componentMap, depth):
	all_genes = []

	for component in componentMap[complex_str]:
		if complexRE.match(component):
			if component in componentMap and depth < 3:
				genes = getGenes(component, componentMap, depth+1)
				for gene in genes:
					all_genes.append(gene)
		else:
			all_genes.append(component)

	return all_genes


# print out a 2-column interactions file of simple PPIs
# protein -> protein
ppi_edges = {}
tf_edges = {}

# for each node, find all interactions, and use the component map to refine them to genes
# if the interaction is a -t>, add it to the TF edge list, otherwise add it to the ppi edge list
for node in nodes:
	proteins = []
	# first break down this node into it's protein constituents
	if nodes[node] == "protein":
		proteins = [ node ]
	elif nodes[node] == "complex":
		proteins = getGenes(node, componentMap, 1)
		
		

	# for each protein, add all interactions to corresponding elements
	for protein in proteins:
		ppi_edges[protein] = [] 
		tf_edges[protein] = [] 

		if protein not in Interactions:
			continue

		for inode in Interactions[protein]:

			type = Interactions[protein][inode]
			if type.startswith("-t"):
				tf_edges[protein].append(gene)	
				continue

			if complexRE.match(inode):
				genes = getGenes(inode, componentMap, 1)
				for gene in genes:
					ppi_edges[protein].append(gene)	
				
	

ppi_out = open(options.ppi_output, 'w')
for source in ppi_edges:

	for sink in ppi_edges[source]:
		ppi_out.write(source+"\t"+sink+"\n")

ppi_out.close()
			
tf_out = open(options.tf_output, 'w')
for source in tf_edges:

	for sink in tf_edges[source]:
		tf_out.write(source+"\t"+sink+"\n")

tf_out.close()

print("done!")			

# print a simple TF interactions file
