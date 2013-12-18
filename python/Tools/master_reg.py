
import operator
import math
import random
import re
# uncomment for use with the Fisher test version
#from scipy import stats
import numpy as np

class ActivityScores: 
	"""
		Uses the supplied pathway to find 

	"""

	def __init__(self, network, scores, min_hub=10, p=1):
		"""
			Input:
				network: net[source] = [(i, t)]
				scores: hash map of differential gene expression (think D-statistics from SAM)
				min_hub: minimum number of genes regulated transcriptionally required 
				to be considered as a potential 'master regulator'
				p: the power to raise each element to when computing the running sum
		"""

		# build a list of candidate regulators
		self.candidates = {}	

		for source in network:

			positive_regulon = set()
			negative_regulon = set()
			for (i, t) in network[source]:
				type, mode = ActivityScores.classifyInteraction(i)	
				# only consider transcriptional regulation
				if mode != 't':
					continue

				if type == 1:
					positive_regulon.add(t)
				elif type == -1:
					negative_regulon.add(t)

			if (len(positive_regulon) + len(negative_regulon)) >= min_hub:
				self.candidates[source] = (positive_regulon, negative_regulon)

		self.generateRankings(scores)
		# for chisquare test
		self.generateCategories(scores)

	@staticmethod
	def	getEnrichmentScore(network, scores, test_set, nperms=1000):
		mrObj = ActivityScores(network, scores, min_hub=10)

		# index all network nodes
		network_nodes = set()
		for s in network:
			network_nodes.add(s)
			for (i, t) in network[s]:
				network_nodes.add(t)

		# generate GSEA score
		score = mrObj.scoreReg(test_set, set())
		# perform random permutations, get background scores
		# FIXME: parallelize permutations
		no_gte = 0.0
		for i in range(0, nperms):
			permuted_set = random.sample(network_nodes, len(test_set))
			p_score = mrObj.scoreReg(permuted_set, set())
			if p_score >= score:
				no_gte += 1.0

		pval = (no_gte+1)/(nperms+1)
		return (score, pval)

	@staticmethod
	def parseHeats(file, network_nodes=None):
		"""
		Parse input heats file in form:
			<gene> <heat> <perturbation/activity sign (+/-)>
			
		Returns:
			- Two hashes: one indexing by gene and storing the input heats, and one storing the input signs
		"""
		
		heats = {}
		signs = {}
		fh = None
		try:
			fh = open(file, 'r')
		except:
			raise Exception("Error: can't open file: "+file)
	
		lineno = 1
		for line in fh:
			parts = line.rstrip().split("\t")
			if len(parts) > 2:
				prot, heat, sign = line.rstrip().split("\t")
	
				# provide a warning if node not in the network
				if network_nodes and prot not in network_nodes:
					sys.stderr.write("Warning: input heat node "+prot+" not in the network and will be ignored...\n")
					continue
	
				# input validation for heat values
				try:
					heats[prot] = float(heat)
				except:
					raise Exception("Error: non float heat value on line "+str(lineno)+" gene "+prot)
	
				# input validation for input signs
				if sign != "+" and sign != "-":
					raise Exception("Error: invalid value for heat sign on line "+str(lineno)+sign)
	
				signs[prot] = sign
			else:
				heats[parts[0]] = float(parts[1])
	
			lineno += 1
	
		fh.close()
		return (heats, signs)

	@staticmethod
	def classifyInteraction(i):
		"""
		
		Returns the edge activation type (-1,0,1), and the textual description
	
		>>> classifyInteraction("component>")
		(0, 'component')
		>>> classifyInteraction("-a>")
		(1, 'a')
		>>> classifyInteraction("-t>")
		(1, 't')
		>>> classifyInteraction("-t|")
		(-1, 't')
		>>> classifyInteraction("-a|")
		(-1, 'a')
		>>> classifyInteraction("HPRD>")
		(1, 'INTERACTS')
		>>> classifyInteraction("REWIRED>")
		(1, 'REWIRED')
		"""
		componentRE = re.compile("^-?component>$")
		activatingRE = re.compile("^-?(\S)>$")
		inactivatingRE = re.compile("^-?(\S)\|$")
		rewiredAC = re.compile("^-?REWIRED>$")
		rewiredIN = re.compile("^-?REWIRED\|$")
		
		if componentRE.match(i):
			return (0, "component")
		elif activatingRE.match(i):
			type = activatingRE.match(i)
			return (1, type.group(1))
		elif inactivatingRE.match(i):
			type = inactivatingRE.match(i)
			return (-1, type.group(1))
		elif rewiredAC.match(i):
			type = "REWIRED"
			return (1, type)
		elif rewiredIN.match(i):
			type = "REWIRED"
			return (-1, type)
		else:
			# default to activating links for HPRD or other protein
			# component links. These are bi-directional
			return (1, "INTERACTS")

	@staticmethod
	def findRegulators(network, de_file, min_hub=10, nperms=1000):
		"""
		Input:
			file with differential expression (or otherwise scored) values 
		
		Returns:
			A hash of master regulators, with signed, weighted scores normalized
			so that absolute values sum to 1.
		"""
		scores, signs = ActivityScores.parseHeats(de_file)
		mrObj = ActivityScores(network, scores, min_hub=min_hub)
		# perform 1000 random permutations of the data to get significance scores for each
		result = mrObj.scoreCandidates(nperms)
		tfs_heats = {}
		for (tf, result) in sorted(result.items(), key=lambda t: t[1][0]):
			# filter on p-value
			if result[1] > 0.05:
				continue
			tfs_heats[tf] = float(result[0])

		if len(tfs_heats) == 0:
			raise Exception("No Significant Regulators Active!")
	
		t_total = 0
		for (g, h) in tfs_heats.items():
			t_total += abs(float(h))

		# normalize abs values to sum to 1000
		norm_factor = 1000.0/t_total
	
		for (g, h) in tfs_heats.items():
			tfs_heats[g] = h*norm_factor

		return tfs_heats

	@staticmethod
	def getPval(real, background):

		count = 0.0
		empirical_pval = None
		if real >= 0:
			# sort in descending order
			for val in sorted(background, reverse=True):
				if val >= real:
					count += 1
				else:
					break
			empirical_pval = (count+1)/(len(background)+1)
		else:
			# ascending order	
			for val in sorted(background, reverse=False):
				if val <= real:
					count += 1
				else:
					break
			empirical_pval = (count+1)/(len(background)+1)

		return empirical_pval


	def scoreCandidates(self, threshold=0.05, nperms=1000):
	
		scores = {}	
		for c in self.candidates:
			pos, neg = self.candidates[c]
			score = self.scoreReg(pos, neg)
			bg = self.generateBackground(c, nperms)
			pval = ActivityScores.getPval(score, bg)
			# filter first by p-value, then weight by the score
			if pval < threshold:
				scores[c] = (score, pval)

		return scores	

	def generateBackground(self, candidate, nperms):
	
		pos, neg = self.candidates[candidate]
		# sample of this set size
		# of random genes to generate each permutation
		background_scores = []
		for i in range(0, nperms):
			sampled_pos = set(random.sample(self.gene_list, len(pos)))
			sampled_neg = set(random.sample(self.gene_list, len(neg)))
			score = self.scoreReg(sampled_pos, sampled_neg)
			background_scores.append(score)	

		return background_scores	

	def generateCategories(self, scores):
		"""
		Used for fisher's exact test: bin positive and negative sets 
		of each
		"""

		# create two sets: genes are either significantly up or down in either
		self.pos_de_set = set()
		self.neg_de_set = set()

		for (gene, score) in sorted(scores.iteritems(), key=operator.itemgetter(1), reverse=True):
			if score > 0:
				self.pos_de_set.add(gene)
			else:
				self.neg_de_set.add(gene)
	

	def generateRankings(self, scores):

		"""
			scores: scores of differential gene expression. These canonically are 
			d-statistic values output from Significance of Microarrays (SAM, Tishirani 2003).
			Input as a hash-map.
			Store the results in the internal index
		"""

		# invert the list, and then merge the postive and negative lists
		# descending order

		# save this data	
		self.gene_list = []
		self.scores = scores

		forward_genes = []
		forward_scores = []
		for (gene, score) in sorted(scores.iteritems(), key=operator.itemgetter(1), reverse=True):
			self.gene_list.append(gene)
			forward_genes.append(gene)
			forward_scores.append(score)
		# ascending order
		reverse_genes = []
		reverse_scores = []
		for (gene, score) in sorted(scores.iteritems(), key=operator.itemgetter(1), reverse=False):
			reverse_genes.append(gene)
			reverse_scores.append(score)

		# maintain two indexes
		indexF = 0
		indexR = 0
		# index by (gene, class (positive or negative))
		R_c = []
		# scores are combined
		R_c_SCORES = []
		while True:

			# termination conditions
			if indexF >= len(forward_genes) and indexR >= len(reverse_genes):
				break
			# append from the other list if one is finished
			elif indexF >= len(forward_genes):
				# the gene name and set are indexed
				R_c.append( (reverse_genes[indexR], '-') )
				R_c_SCORES.append( -reverse_scores[indexR] )
				indexR += 1
				continue
			elif indexR >= len(reverse_genes):
				R_c.append( (forward_genes[indexF], '+') )
				R_c_SCORES.append( forward_scores[indexF] )
				indexF += 1
				continue
					
			f_score = forward_scores[indexF]
			# inverse score...
			r_score = -reverse_scores[indexR]

			if f_score > r_score:
				R_c.append( (forward_genes[indexF], '+') )
				R_c_SCORES.append( f_score )
				indexF += 1
			else:
				R_c.append( (reverse_genes[indexR], '-') )
				R_c_SCORES.append( r_score )
				indexR += 1

		self.scores = R_c_SCORES
		self.list = R_c	

	def scoreReg(self, pos_query_set, neg_query_set):
		"""
			
		"""

		# from Lim et al., 2009 PSB
		rs_const = float(2.0*len(self.scores)-(len(pos_query_set)+len(neg_query_set)))
		running_sum = 0.0

		# -- norm const
		sum_norm_const = 0.0
		for i in range(0, len(self.list)):
			gene, set = self.list[i]
			if (set == '-' and gene in neg_query_set) or (set == '+' and gene in pos_query_set):
				# compute the sum of abs values of all scores in this set to get a normalization 
				# constant at the end
				sum_norm_const += abs(self.scores[i])

		# FIXME: handle this with a better error indication
		if sum_norm_const == 0:
			return 0

		running_sum = 0.0
		max_rs = 0
		min_rs = 0
		for i in range(0, len(self.list)):

			gene, set = self.list[i]
			if (set == '-' and gene in neg_query_set) or (set == '+' and gene in pos_query_set):
				running_sum += self.scores[i]/sum_norm_const
			else:
				# score decreases in this case
				running_sum -= 1/rs_const	

			if running_sum > max_rs:
				max_rs = running_sum	
			elif running_sum < min_rs:
				min_rs = running_sum	

		return max_rs+min_rs


