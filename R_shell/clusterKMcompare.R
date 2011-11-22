#!/usr/bin/env Rscript
# Calculates the adjusted Rand Index between 2 clusterings
#
# Input: 2 directories containing .kag files produced by k-means clustering (i.e. cluster-eisen)
# to do an all vs all comparison
# Output: the adjusted rand index between each possible pair in a tab-delineated matrix format
#
# Uses: mclust.adjustedRandIndex 
# Date: Nov, 2011
# Author: Evan Paull
#
# You can cite Yeung 2001 (Validating Clustering for Gene Expression Data) 
# if using the adjusted rand index for a paper.

library(getopt)
library(mclust)

opt = getopt(matrix(c(
    'type', 't', 1, "character",
    'f1', 'f', 1, "character",
    'f2', 'e', 1, "character",
    'out', 'o', 1, "character"
	),ncol=4,byrow=TRUE));

if (opt$type != 'kmeans') {
	print ("only the kmeans type is supported at this time (requires .KAG files input)")
	q();
}
# take a 2 named vectors of clusterings (the names are the cluster assignments,
# and the values are the cluster members). 
# The cluster members must be identical
compareKMClusterings <- function(file1, file2) {

	m1 <- as.matrix(read.delim(file=file1, sep="\t"))
	m2 <- as.matrix(read.delim(file=file2, sep="\t"))

	# sort both matrices by the name
	m1 <- m1[order(m1[,1]),]
	m2 <- m2[order(m2[,1]),]
	if (!identical(m1[,1],m2[,1])) {
		print ("Error: samples clustered are not equal!")
		q();
	}
	return (adjustedRandIndex(m1[,2], m2[,2]))
}


# calculate the ARI between every possible pair and print to a matrix
# clustering files are in each directory
setsCompare <- function(dir1, dir2) {
	
	set1 <- list.files(path=dir1, pattern="*.kag", full.names=TRUE)
	set2 <- list.files(path=dir2, pattern="*.kag", full.names=TRUE)

	# store results in a new matrix: set1 is the rows, set2 the columns
	# this will ultimately be a CDT file, so add 2 columns just for names
	m <- matrix(ncol=length(set1)+2, nrow=length(set2)+2)
	row <- 3
	for (f1 in set1) {
		col <- 3
		for (f2 in set2) {
			 m[row, col] <- compareKMClusterings(f1,f2)
			col <- col + 1
		}
		# move to the next row
		row <- row + 1
	}

	# first 2 rows are set2 names...
	m[1,] <- c("X", "X", set2)
	m[2,] <- c("X", "X", set2)
	m[,1] <- c("X", "X", set1)
	m[,2] <- c("X", "X", set1)
	return (m)	
}

all_v_all <- setsCompare(opt$f1, opt$f2)
print (paste("writing to ", opt$out, collapse=" "))
write.table(all_v_all, file=opt$out, row.names=FALSE, col.names=FALSE, sep="\t", quote=FALSE)

# K-means: 
#ARI <- compareKMClusterings(opt$f1, opt$f2)
#print(paste("Adjusted Rand Index Between Clusterings :", opt$f1, " and ", opt$f2, collapse=""))
#print (ARI)

# example usage: 
# a <- sample(1:3, 9, replace = TRUE)
# b <- sample(c("A", "B", "C"), 9, replace = TRUE)
# adjustedRandIndex(a, b)
# Takes 2 vectors of cluster labels: 
