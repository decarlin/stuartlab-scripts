#!/usr/bin/env python

# Usage: median-center.py -n [optional normals matrix file] <tumor expression matrix>
# Median center by the medians of normals (if supplied) otherwise median-center on the data

from optparse import OptionParser
from math import log
import operator
parser = OptionParser()
parser.add_option("-n","--normals",dest="normals",action="store",default=None)
(opts, args) = parser.parse_args()

def parseMatrix(file):
	
	header = None
	genes = []
	samples = {}
	for line in open(file, 'r'):
		parts = line.rstrip().split("\t")
		gene = parts[0]

		if not header:
			header = parts	
			for i in range(1, len(header)):
				samples[header[i]] = {}	
			continue

		genes.append(gene)
	
		for i in range(1, len(parts)):
			val = float(parts[i])
			sample_name = header[i]
			samples[sample_name][gene] = val
		
	return (samples, header, genes)

def printValues(s, g, vals):
	print "\t".join(s) 
	for gene in g:
		printstr = gene
		for sample in s[1:]:
			value = "NA"
			if gene in vals[sample]:
				value = vals[sample][gene]
			printstr += "\t"+str(value)
		print printstr	

def getMedians(values_by_sample):
	values_by_gene = {}
	for sample in values_by_sample:
		for gene in values_by_sample[sample]:
			if gene not in values_by_gene:
				values_by_gene[gene] = []
			values_by_gene[gene].append(values_by_sample[sample][gene])

	medians = {}
	for gene in values_by_gene:
		medians[gene] = sorted(values_by_gene[gene])[len(values_by_gene[gene])/2 + 1]

	return medians

def medianCenter(gene_values, center_by):

	centered = {}
	for gene in gene_values:
		if gene not in center_by:
			continue
		centered[gene] = gene_values[gene] - center_by[gene]

	return centered

# parse tumor samples
samples_gene_values, all_samples, all_genes = parseMatrix(args[0])
centered = {}
medians = None
 
# normal controls, if supplied, otherwise use medians from the data
if opts.normals:
	normals, n_samples, n_genes = parseMatrix(opts.normals)
	medians = getMedians(normals)
else:
	medians = getMedians(samples_gene_values)


for sample in samples_gene_values:
	centered[sample] = medianCenter(samples_gene_values[sample], medians)

printValues(all_samples, all_genes, centered)
