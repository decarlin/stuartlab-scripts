#!/usr/bin/env Rgetopt.py
library(impute)

library(Rgetopt)

argspec <- c("imputeknn.R - impute missing expression data using KNN
Usage:
    imputeknn.R [options] data.tab > out.tab
Options:",
             "k=i  number of neighbors in the imputation (default 10)",
             "randomseed=i random number generator seed (default 362436069)",
             "h=i  header lines (default 1)",
             "ac=i number of annotation columns (default 1)")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]
  defaults <- list(randomseed=362436069, k=10, h=1, ac=1)
  o <- Rgetopt(argv=argv, argspec=argspec, defaults=defaults)

  if (length(o$argv) != 1) usage("must specify one file option", argspec)

  infile <- parseReadableFile(o$argv)

  headers <- readLines(infile, n=o$h)

  d.df <- read.delim(infile, header=F, row.names=NULL, stringsAsFactors=FALSE)
  ac.cols <- 1:ncol(d.df) > o$ac
  data <- as.matrix(d.df[,ac.cols])
  if (!is.numeric(data)) stop("Non-numeric data in matrix, check -ac")

  sink(stderr()) # impute.knn is noisy and outputs cluster sizes
  imputed <- impute.knn(data, k=o$k, rng.seed=o$randomseed)
  sink(NULL)

  writeLines(headers)
  write.table(data.frame(d.df[,!ac.cols], data), file=stdout(),
              sep="\t", quote=FALSE, row.names=FALSE, col.names=FALSE)
}

main()
