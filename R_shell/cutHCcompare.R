#!/usr/bin/env Rscript
# H-Clusters 2 tab-delineated matrix files, cuts them into a specified number of clusters
# and calculates the adjusted Rand Index between 2 clusterings
#
# Input: 2 matrix files, the number of clusters to use to compare
# to do an all vs all comparison
# Output: the adjusted rand index between clusterings
#
# Uses: mclust.adjustedRandIndex , stats, cluster
# Date: Nov, 2011
# Author: Evan Paull
#
# You can cite Yeung 2001 (Validating Clustering for Gene Expression Data) 
# if using the adjusted rand index for a paper.

#usage, options and doc goes here
argspec <- c("cutHCcompare.R H-Clusters 2 tab-delineated matrix files, cuts them into a specified number of clusters and calculates the adjusted Rand Index between 2 clusterings. 

	Usage: 
		cutHCcompare.R -m <matrix1.tab> -n <matrix2.tab>  -k '5'
	Options:
		k = the number of clusters to produce from a h-clustering, using cuttree\n")

if (commandArgs(TRUE)=="--help") { 
	write(argspec, stderr())
	q();
}

library('getopt')

opt = getopt(matrix(c(
    'm1' , 'm', 1, "character",
    'm2' , 'n', 1, "character",
    'k' , 'k', 1, "character"
	),ncol=4,byrow=TRUE));

library(stats)
library(cluster)
library(mclust)

groupHC <- function(mr, num_clusters) {

	m <- scale(mr)
	d <- dist(m, method="euclidean")
	fit <- hclust(d, method="ward")
	groups <- cutree(fit, num_clusters)
	return (groups)
}

groupKM <- function(mr, num_clusters) {

	m <- scale(mr)
	fit <- kmeans(m, num_clusters)
	print (fit)
	return (fit)
}

compareHCclusterings <- function(file1, file2, k) {
	m1 <- as.matrix(read.delim(file1, sep="\t", header=TRUE, row.names=1))
	m2 <- as.matrix(read.delim(file2, sep="\t", header=TRUE, row.names=1))

	# sort both matrices by the name
	m1 <- m1[order(m1[,1]),]
	m2 <- m2[order(m2[,1]),]
	if (!identical(m1[,1],m2[,1])) {
		print ("Error: samples clustered are not equal!")
		q();
	}

	group1 <- groupHC(m1, k)
	group2 <- groupHC(m2, k)
	return (adjustedRandIndex(group1, group2))
}

print (compareHCclusterings(opt$m1, opt$m2, opt$k))

# vec1 assignments, vec2 assignments in the same order


#m <- as.matrix(read.delim(file, sep="\t", header=TRUE, row.names=1))
#m <- scale(m)
#d <- dist(m, method="euclidean")
#fit <- hclust(d, method="ward")
#plot(fit)
#groups <- cutree(fit, 3)
#rect.hclust(fit, k=5, border="red")
