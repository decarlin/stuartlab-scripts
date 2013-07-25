#!/usr/bin/env python

# Perform exponential normalization of sample data:
# Rank genes per sample, take -log(1-rank), where 1 is the best, and zero the worst rank

from optparse import OptionParser
from math import log
import operator
parser = OptionParser()
parser.add_option("-m","--matrix",dest="matrix",action="store",default=None)
(opts, args) = parser.parse_args()

def expNormRank(rank):
	"""
	Input: rank: 0 to 1 floating point value (lowest to highest rank)
	"""

	val = -log(1-rank)

	return val

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

def rankGenes(gene_values):

	exp_norm_vals = {}
	num_items = len(gene_values)
	# rank in ascending order
	ranked = sorted(gene_values.iteritems(), key=operator.itemgetter(1))
	for i in range(0, num_items):
		gene, val = ranked[i]	
		rank_val = float(i)/num_items
		exp_norm_vals[gene] = expNormRank(rank_val)
		
	return exp_norm_vals	

samples_gene_values, all_samples, all_genes = parseMatrix(opts.matrix)
samples_exp_vals = {}
for sample in samples_gene_values:
	samples_exp_vals[sample] = rankGenes(samples_gene_values[sample])


print "\t".join(all_samples) 
for gene in all_genes:
	printstr = gene
	for sample in all_samples[1:]:
		printstr += "\t"+str(samples_exp_vals[sample][gene])
	print printstr	
