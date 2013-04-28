#!/usr/bin/env Rscript

# Takes a table with samples as rows, and genes as columns, and computes the differential proportions between
# subtype.
# Colums: gene ids
# Rows: sample ids
# Values: 1/0 = mutation status 
#

library('getopt')
options(warn=-1)

opt = getopt(matrix(c(
    'help' , 'h', 1, "character",
    'data' , 'n', 1, "character",
    'dichotomy' , 'd', 1, "character",
    'stat' , 's', 1, "character",
    'min_mut' , 'm', 1, "character",
    'output' , 'a', 1, "character"
	),ncol=4,byrow=TRUE));

SIG = 0.05
EPSILON = 0.001

SIG = SIG+EPSILON

if (!is.null(opt$help) || is.null(opt$data) || is.null(opt$output) || is.null(opt$dichotomy)) {
	self = commandArgs()[1];
	#print a friendly message and exit with a non-zero error code
	cat(paste("Usage: ",self,"  --input proportions +/- matrix --output p-vals-file \n"))
	q();
}

if (is.null(opt$min_mut)) {
	opt$min_mut <- 1
}

data <- read.delim(opt$data, sep="\t", header=TRUE,row.names=1)
divisions <- read.delim(opt$dichotomy, sep="\t", header=FALSE, row.names=1)

# merge by row
# this should result in a matrix with the first column the sample names, the second
# the sample assignments, then the data
merged <- as.matrix(merge(divisions, data, by=0))
# the first column contains the subtype id
group1_indexes <- which(as.numeric(merged[,2]) == "1")
group2_indexes <- which(as.numeric(merged[,2]) == "0")
output <- matrix(ncol=5)
output <- rbind(output, c("Gene", "Statistic", "P-val", "Proportion", "Sign"))

# first col is the sample id, second column is subtype
# iterate over the columns
for (i in c(3:dim(merged)[2])) {

	gene_name <-  colnames(merged)[i]

	print(paste("testing gene", gene_name))
	group1 <- as.numeric(merged[group1_indexes,i])
	mut_g1 <- length(which(group1 == 1))
	non_mut_g1 <- length(which(group1 == 0))

	group2 <- as.numeric(merged[group2_indexes,i])

	mut_g2 <- length(which(group2 == 1))
	non_mut_g2 <- length(which(group2 == 0))

	r1 <- mut_g1/non_mut_g1
	r2 <- mut_g2/non_mut_g2

	if (r1 > r2) {
		sign <- "+"
	} else {
		sign <- "-"
	}
	
	fold = r1/r2

	test_m <- matrix(c(mut_g1, non_mut_g1, mut_g2, non_mut_g2), ncol=2, byrow=TRUE)
	rownames(test_m) <- c("G1", "G2")
	ssig <- chisq.test(test_m)

	#print(paste(gene_name, "g1:", mut_g1, non_mut_g1, sep=",", collapse=","))
	#print(paste(gene_name, "g2:", mut_g2, non_mut_g2, sep=",", collapse=","))
	# pval = enough genes to make a call
	# -1 = mutated, but not enough to test, or not significant
	# -2 = not mutated
	if (mut_g2 > as.numeric(opt$min_mut)) {
		mut_status <- ssig$p.value
		if (mut_status > SIG) {
			mut_status = -1
		}
	} else if (mut_g1 > as.numeric(opt$min_mut)) {
		mut_status <- ssig$p.value
		if (mut_status > SIG) {
			mut_status = -1
		}
	} else if (mut_g1 == 0) {
		if (mut_g2 == 0) {
			mut_status <- -2
		} else {
			mut_stats <- -1
		}
	} else {
		mut_status <- -1
	}


	#print (ssig$statistic)
	output <- rbind(output, c(gene_name, ssig$statistic, ssig$p.val, fold, sign))

}

#warnings();
write.table(output[2:dim(output),], file=opt$output, quote=FALSE, sep="\t", row.names=FALSE, col.names=FALSE)
