#!/usr/bin/env Rgetopt.py
library(Rgetopt)
library(mixgauss)
library(logsum)
library(KnockoutNets)

argspec <-
  c("KNpairscores.R - calculate pair scores from egenes.logprobs,
from KNgaussQuantize.R.  Outputs a tab-delimited file to standard out.

Usage:

  KNpairscores.R <egenes.logprobs file>",
    "help    print help",
    "o=s     output to this file (defaults to stdout)",
    "perm=s  \"permute\" input data: one of gene, array, all, or bootstrap",
    "tiers=s use the tier structure (for permutation) from this file.
          This is necessary when multiple platforms were used and some
          E-genes are not on all arrays.",
    "outputEGLP=s  if -perm or -bootstrap is set, save the data here"
    )

main <- function() {
  o <- Rgetopt(argspec=argspec)

  if (length(o$argv) != 1) usage("specify a file", argspec)
  stopifnot(file.access(o$argv) == 0)
  elp.names <- load(o$argv[1])
  if (!("egenes.logprobs" %in% elp.names)) {
    usage("need an object with egenes.logprobs", argspec)
  }

  egenes.logprobs <- doPermutationIfNeeded(egenes.logprobs, o)

  kd <- names(egenes.logprobs)
  pairs <- expand.grid(A=kd, B=kd)[as.vector(upper.tri(diag(length(kd)))),]
  
  alphaPriors <- pairPriors(paramGen(3,1))
  summarization <- max
  pairscores <- scorePairsWithPriorsLog(pairs, egenes.logprobs,
                                        alphas=alphaPriors,
                                        summarization=summarization)
  if (is.null(o$o)) o$o <- stdout()
  write.table(pairscores, file=o$o, quote=F, row.names=F, sep="\t")
}

doPermutationIfNeeded <- function(egenes.logprobs, o) {
  if (!is.null(o$perm)) {
    if (is.null(o$tiers)) {
      permFunction <- switch(o$perm,
                             gene=genePerm, array=koPerm, all=totalPerm,
                             bootstrap=bootstrapEgenes)
      if (is.null(permFunction)) {
        usage("Invalid permutation, please choose one of gene, array, all",
              "", finish=q(status=1))
      }
      egenes.logprobs <- permFunction(egenes.logprobs)
    } else {
      if (o$perm != "array") {
        usage("tier-based permutation only available for arrays",
              finish=q(status=1))
      }
      tiers <- scan(o$tiers, what="", quiet=TRUE)
      stopifnot(length(tiers) == length(egenes.logprobs))
      egenes.logprobs <- tierBasedKoPerm(egenes.logprobs, tiers)
    }
    if (!is.null(o$outputEGLP)) save(egenes.logprobs, file=o$outputEGLP)
  }
  return(egenes.logprobs)
}

genePerm <- function(elp.o) {
  elp <- elp.o
  for(i in 1:nrow(elp[[1]])) {
    o <- sample(length(elp))
    for (j in 1:length(o)) {
      elp[[j]][i,] <- elp.o[[o[j]]][i,]
    }
  }
  return(elp)
}

bootstrapEgenes <- function(elp) {
  genes <- sample(seq(1, length.out=nrow(elp[[1]])), replace=TRUE)
  elp <- lapply(elp, function(x) return(x[genes, , drop=FALSE]))
  return(elp)
}


tierBasedKoPerm <- function(elp, tiers) {
  na <- sapply(elp, function(ko) rowSums(is.na(ko) > 0))
  for (tier in unique(tiers)) {
    tiereffects <- rowSums(na[, tiers == tier]) == 0
    for (i in which(tiers == tier)) {
      elp[[i]][tiereffects,] <- elp[[i]][sample(which(tiereffects)), ]
    }
  }
  return(elp)
}

koPerm <- function(elp.o) {
  return(lapply(elp.o, function(x) return(x[sample(1:nrow(x)), ,drop=FALSE])))
}

totalPerm <- function(elp.o) {
  shuffle <- matrix(sample(1:(length(elp.o) * nrow(elp.o[[1]]))),
                    ncol=length(elp.o))
  cols <- col(shuffle)
  rows <- row(shuffle)
  elp <- elp.o
  for(j in 1:length(elp.o)) {
    for(i in 1:nrow(elp.o[[j]])) {
      s <- shuffle[i,j]
      elp[[j]][i,] <- elp.o[[cols[s]]][rows[s],]
    }
  }
  return(elp)
}

if (Sys.getenv("RGETOPT_DEBUG") != "") {debug(main)}
main()
