#!/usr/bin/env Rscript

# EDGER.R: 
#  Runs the EdgeR algorithm on raw RNA-Seq counts data to compute the differential expression between
#  two categories, defined by binary column labels. 
#
# For more information, see the edgeR tutorial that this script was adapted from 
# http://cgrlucb.wikispaces.com/file/view/edgeR_Tutorial.pdf
# 
# Required Packages: edgeR
#
# Author: Evan Paull 
# Date: Jan, 2013

options(warn = -1)
library('getopt')

opt = getopt(matrix(c(
    'help' , 'h', 1, "character",
    'expr' , 'e', 1, "character",
    'groups' , 'g', 1, "character",
    'output' , 'o', 1, "character"
	),ncol=4,byrow=TRUE));

if (!is.null(opt$help) || is.null(opt$expr)) {
	self = commandArgs()[1];
	#print a friendly message and exit with a non-zero error code
	cat(paste("Usage: ",self,"  --expr <expression file> --groups <binary vector: first column assignments>\n"))
	q();
}

library(edgeR)

raw.data <- read.delim(opt$expr, sep="\t", header=TRUE,row.names=1)
counts <- raw.data
assignments <- as.matrix(read.delim(opt$groups, sep="\t", header=TRUE))
groups <- as.numeric(assignments[,2])
if (!isTRUE(all.equal(assignments[,1], colnames(raw.data)))) {
	print ("Error: group assignments not in the same order as data columns: use join.pl first")
	quit();
}
# needs to be in order

# create DGE List object from counts, assignments
cds <- DGEList(counts, group = groups)
# filter out low count reads, impossible to detect in DE. Keep only genes with at least 1 read per million in at least 3 samples. 
# calculate the normalization factors which correct for the compositions of each sample. 
cds <- cds[rowSums(1e+06 * cds$counts/expandAsMatrix(cds$samples$lib.size, dim(cds)) > 1) >= 3, ]
cds <- calcNormFactors( cds )
cds <- estimateCommonDisp( cds )

# estimate tagwise dispersion 50(#samples - #groups)
cds <- estimateTagwiseDisp(cds)

# get list using tagwise (gene) dispersion estimates
de.tgw <- exactTest( cds , dispersion="tagwise" , pair = c( "0" , "1" ) )

# sort results by logpval
resultsByFC.tgw <- topTags( de.tgw , n = nrow( de.tgw$table ) , sort.by = "p.value" )$table

write.table(resultsByFC.tgw, file=opt$output, sep="\t",quote=FALSE)
