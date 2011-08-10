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

def getGenes(complex_str, componentMap):

	all_genes = []
	for component in componentMap(complex_str):
		if complexRE.matches(component):
			genes = getGenes(component, componentMap)
			for gene in genes:
				all_genes.append(gene)
		else:
			all_genes.append(component)

	return all_genes


def enumType(type_str):




# print out a 2-column interactions file of simple PPIs
# protein -> protein
ppi_edges = {}
tf_edges = {}

# for each node, find all interactions, and use the component map to refine them to genes
# if the interaction is a -t>, add it to the TF edge list, otherwise add it to the ppi edge list
for node in nodes:
	if nodes[node] == "protein":
		ppi_edges[node] = [] 
		tf_edges[node] = [] 
		for inode in Interactions[node]:
			type = Interactions[node][inode]
			if (complexRE.matches(inode)):
				genes = getGenes(inode)
				for gene in genes:
					if enumType(type) is TF:
						tf_edges[node].append(gene)	
					else:
						ppi_edges[node].append(gene)	
				
		


# print a simple TF interactions file
