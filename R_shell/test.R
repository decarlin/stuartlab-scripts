#!/usr/bin/env Rgetopt.py
library(Rgetopt)
library(logsum)
library(mixgauss)
library(KnockoutNets)

argspec <- c("KNgaussQuantize.R - convert an egenes.tab file into an
egenes.logprob file. An egenes.tab file contains additional header rows,
and each header row begins with a name of the header with a colon suffix.
A knockdown.cols: header row is required, and describes which gene was
knocked down under each microarray hybridiziation. An example file:

  knockdown.cols:  sgeneA  sgeneA  sgeneB
  Egene            sA_rep1 sA_rep2 sB_rep1
  egene1           -3.2    -1.7    0.1
  egene2           5.2      5.1    -4.9

Usage:
  KNgaussQuantize.R [options] egenes.tab",
             "mean=f    separation between null and effect dist (default 1.5)",
             "sd=f      standard deviation of distributions (default 1.0)",
             "params=rf file with a parameter matrix
    (command line options will modify this, if specified)",
             "combine=s replicate combination mode. Three possible values:
        independent   product of individual likelihoods
        pessimistic   minimum likelihood of replicates
        optimistic    maximum likllihood of replicates",
             "o|output=s  store output to this file"
             )

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]
  o <- Rgetopt(argv=argv, argspec=argspec)
  if (length(o$argv) != 1) {
    usage("Need a file argument", argspec)
  }
  
  if (is.null(o$params)) {
    params <- paramGen(offset=1.5, sd=1.0)
  } else {
    params <- as.matrix(read.table(paramfile))
    if (!isValidParamMatrix(params)) usage("invalid parameter matrix", argspec)
  }

  if (!is.null(o$mean)) {
    params['neg','mean'] <- -o$mean
    params['pos','mean'] <- o$mean
  }

  if (!is.null(o$sd)) {
    params[,'sd'] <- o$sd
  }
  
  summarize.index <- pmatch(o$combine, c("independent", "pessimistic", "optimistic"))
  if (length(summarize.index) < 1) summarize.index <- 1
  if (is.na(summarize.index)) {
    usage("disallowed --combine value", argspec)
  }

  summarize <- list(sum, min, max)[[summarize.index]]

  egenes <- read.egene.tab(o$argv)

  if (is.null(o$keepall)) {
    egenes$egenes <- egenes$egenes[,egenes$knockdown.cols %in% egenes$lof]
    egenes$knockdown.cols <- egenes$knockdown.cols[egenes$knockdown.cols
                                                   %in% egenes$lof]
  }

  egenes.logprobs <- exprToRegLogProbs(egenes$egenes, egenes$knockdown.cols, 
                                       params, summarize=summarize)

  if (is.null(o$o)) {
    o$o <- file(deferredStdOutFile(), open="wb")
  } else {
    o$o <- file(o$o, open="wb")
  }
  save(egenes.logprobs, file=o$o)
}

main()
