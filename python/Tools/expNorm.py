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

	val = abs(log(1-rank))

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

def separateZeros(gene_values):

	zeros = []
	all_other = {}
	for gene in gene_values:
		val = gene_values[gene]	
		if val == 0:
			zeros.append(gene)
		else:
			all_other[gene] = val
	
	return (all_other, zeros)	
			
def expRankGenes(gene_values, uniform_after_zero=True):
	"""
	Rank genes: separate all zero entries, and give them all a zero rank

	Input:
		uniform_after_zero: if True, let the first non-zero entry have a relative rank of 2,
		otherwise have it be the sum of all zero entries plus one, and uniform to 1 after that. 
	
	Returns:
		A Hash of exponential normalized values
	"""
	# separate-out zero entries
	non_zero_values, zeros = separateZeros(gene_values)

	# populate this hash
	exp_norm_vals = {}

	# assign zero rank to all zero-score genes
	for gene in zeros:
		exp_norm_vals[gene] = expNormRank(0)

	# rank only non-zero entries in ascending order
	if uniform_after_zero:
		ranked = sorted(non_zero_values.iteritems(), key=operator.itemgetter(1))
		for i in range(0, len(non_zero_values)):
			gene, val = ranked[i]	
			rank_val = float(i)/len(non_zero_values)
			exp_norm_vals[gene] = expNormRank(rank_val)
	else:
		ranked = sorted(non_zero_values.iteritems(), key=operator.itemgetter(1))
		for i in range(len(zeros)+1, len(gene_values)):
			gene, val = ranked[i-len(zeros)-1]	
			rank_val = float(i)/len(gene_values)
			exp_norm_vals[gene] = expNormRank(rank_val)
		
	return exp_norm_vals	

samples_gene_values, all_samples, all_genes = parseMatrix(opts.matrix)
samples_exp_vals = {}
for sample in samples_gene_values:
	samples_exp_vals[sample] = expRankGenes(samples_gene_values[sample])


print "\t".join(all_samples) 
for gene in all_genes:
	printstr = gene
	for sample in all_samples[1:]:
		printstr += "\t"+str(samples_exp_vals[sample][gene])
	print printstr	
