#!/usr/bin/env Rgetopt.py
library(tools)
library(Biobase)
library(splines)
library(survival)
library(multtest)
library(siggenes)

library(Rgetopt)

argspec <- c("sam.R - run Significance Analysis of Microarrays (SAM) on a
data matrix.  The top row should contain the classification, and every
subsequent row should have data.  The first two columns should have annotation
data (use the -ac option to change this).
mUsage:
    sam.R [options] input.tab > output.tab
Options:",
             "ac=i  annotation columns (default 2)")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]
  
  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(ac=2))

  if (length(o$argv) != 1) usage("Must specify one file option", argspec)

  infile <- parseReadableFile(o$argv)

  header <- strsplit(readLines(con=infile, n=1), "\t")[[1]]
  cl.cols <- 1:length(header) > o$ac
  cl.string <- header[cl.cols]
  cl <- as.integer(cl.string)
  if (any(cl != cl.string)) stop("Found non-integers in class labels")

  data.df <- read.delim(infile, header=FALSE, row.names=NULL,
                        stringsAsFactors=FALSE)
  # close(infile)
  data <- as.matrix(data.df[,cl.cols])

  if(!is.numeric(data)) stop("Non-numeric data in matrix")
  if(length(cl) != ncol(data)) stop("Header length does not match data")

  sink(stderr()) # sam() is noisy and prints to stdout
  s <- attributes(sam(data, cl))
  sink(NULL)
  warnings()


  r <- data.frame(data.df[,!cl.cols],
                  s[c("d", "vec.false", "q.value", "p.value", "s")])
  r <- r[order(r[,'d'], decreasing=TRUE),]
  colnames(r) <- c(header[!cl.cols], "Score(d)", "FalseCalls", "Q-value",
                   "P-value", "StdDev(s)")

  write.table(r, stdout(), quote=FALSE, sep="\t", row.names=FALSE)
}

main()
