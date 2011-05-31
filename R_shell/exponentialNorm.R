#!/usr/bin/Rscript

#usage, options and doc goes here
argspec <- c("exponentialNorm.R - takes any flat file and normalizes the columns to a standard (lambda equals one) exponential distribution.  Requires a single header line and a single cloumn of annotation.

Usage:
    exponentialNorm.R input.tab > output.tab
Options:

	ac = annotation columns default 1")

main <- function(argv) {
  
  infile <- argv

  if(argv==c('--help')){ write(argspec, stderr())
  q();
  }

  header <- strsplit(readLines(con=infile, n=1), "\t")[[1]]
  
  cl.cols<- 1:length(header) > 1
  
  data.df <- read.delim(infile, header=TRUE, row.names=NULL,
                        stringsAsFactors=FALSE, na.strings="NA")
  # close(infile)
  data <- as.matrix(data.df[,cl.cols])

  if(!is.numeric(data)) stop("Non-numeric data in matrix")

  rankNA <- function(col)
  { col[!is.na(col)]<-(rank(col[!is.na(col)])/sum(!is.na(col)))-(1/sum(!is.na(col)))
  col
}

  b<-apply(data,2,rankNA)
  c<-apply(b, c(1,2),qexp)

  row.names(c)<-data.df[,1]
  write.table(t(header), quote =FALSE, sep="\t", row.names=FALSE, col.names=FALSE)
  write.table(c, stdout(), quote=FALSE, sep="\t", row.names=TRUE, col.names=FALSE)
}

main(commandArgs(TRUE))
