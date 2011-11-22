#!/usr/bin/env Rscript

# H-Clusters 2 directories each containing tab-delineated matrix files, 
# cuts each into a specified number of clusters
# and calculates the adjusted Rand Index between all possible pairs between
# directories
#
# Input: 2 directories and the number of clusters to use to compare
# to do an all vs all comparison
# Output: the adjusted rand index between clusterings
#
# Uses: mclust.adjustedRandIndex , stats, cluster
# Date: Nov, 2011
# Author: Evan Paull
#
# You can cite Yeung 2001 (Validating Clustering for Gene Expression Data) 
# if using the adjusted rand index for a paper.

library('getopt')

opt = getopt(matrix(c(
    'f1', 'f', 1, "character",
    'f2', 'e', 1, "character",
    'km', 'k', 1, "character",
    'out', 'o', 1, "character"
	),ncol=4,byrow=TRUE));

library(mclust)
library(stats)
library(cluster)


# ---
groupHC <- function(data, num_clusters) {
	data <- scale(data)
	d <- dist(data, method="euclidean")
	fit <- hclust(d, method="ward")
	groups <- cutree(fit, num_clusters)
	return (groups)
}

compareHCclusterings <- function(file1, file2, k) {

	mat1 <- as.matrix(read.table(file1, sep="\t", header=TRUE, row.names=1))
	mat2 <- as.matrix(read.table(file2, sep="\t", header=TRUE, row.names=1))

	# sort both matrices by the name
	mat1 <- mat1[order(rownames(mat1)),]
	mat2 <- mat2[order(rownames(mat2)),]
	if (!identical(rownames(mat1), rownames(mat2))) {
		print ("Error: names not identical!")
		q();
	}

	group1 <- groupHC(mat1, k)
	group2 <- groupHC(mat2, k)
	return (adjustedRandIndex(group1, group2))
}

# calculate the ARI between every possible pair and print to a matrix
# clustering files are in each directory
setsCompare <- function(dir1, dir2, k) {
	
	set1 <- list.files(path=dir1, pattern="*.tab", full.names=TRUE)
	set2 <- list.files(path=dir2, pattern="*.tab", full.names=TRUE)

	# store results in a new matrix: set1 is the rows, set2 the columns
	# this will ultimately be a CDT file, so add 2 columns just for names
	m <- matrix(ncol=length(set1)+2, nrow=length(set2)+2)
	row <- 3
	for (f1 in set1) {
		col <- 3
		for (f2 in set2) {
			 m[row, col] <- compareHCclusterings(f1,f2,k)
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

all_v_all <- setsCompare(opt$f1, opt$f2, opt$k)
print (paste("writing to ", opt$out, collapse=" "))
write.table(all_v_all, file=opt$out, row.names=FALSE, col.names=FALSE, sep="\t", quote=FALSE)
