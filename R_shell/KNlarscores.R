#!/usr/bin/env Rgetopt.py

library(Rgetopt)

library(polynom)
library(logsum)
library(mixgauss)
library(lattice)
library(KnockoutNets)

argspec <- c("KNlarscores.R - Calculate the likelihood of a model and output
LAR scores for each effect-gene to standard output.

Usage:
    KNlarscores.R [options] pairscores.tab egenes.logprobs.RData
Options:",
             "llscore=wf   write the total log-likelihood of the model to this file",
             "permute      permute each E-gene's expression values",
             "o=s          write output to this file (defaults to stdout)")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec)

  if (length(o$argv) != 2) {
    usage("wrong number of arguments", argspec=argspec)
  }

  pairfile <- o$argv[1]
  eglpfile <- o$argv[2]

  pairll <- read.delim(pairfile, stringsAsFactors=FALSE)
  stopifnot(isValidScoreMatrix(pairll))
  network <- likelihoodToAdj(pairll)

  ## Topologically sort the network.  This is important in the case of ties
  ## in LAR scores, so that we choose the highest point in the network
  ## rather than an arbitrary point.  Though we don't have evidence
  ## that it's at the top versus another location, at least it's based
  ## on the network topology rather than the input order of the genes.
  tsort <- topological.sort.with.equiv(signedAcc(network))
  network <- network[tsort,tsort,drop=FALSE]

  a <- load(eglpfile)
  stopifnot("egenes.logprobs" %in% a)
  if (!is.null(o$permute)) egenes.logprobs <- genePerm(egenes.logprobs)

  tsort.names <- rownames(network)
  stopifnot(names(egenes.logprobs) %in% tsort.names,
            length(egenes.logprobs) == length(tsort.names))
  egenes.logprobs <- egenes.logprobs[tsort.names]
  
  scores <- scoreModel(network, egenes.logprobs)
  
  if (!is.null(o$llscore)) cat(scores$ll, "\n", file=o$llscore)
  
  ##
  ##  LLR connection point
  ##
  u <- (ncol(scores$posterior)+1)/2
  connection <- colnames(scores$posterior)[-u][apply(scores$posterior[,-u],
                                                     1, which.max)]
  conn.sgene <- sub("^neg_", "", sub("^pos_","", connection))
  conn.sign <- (regexpr("^pos_", connection) > 0) -
    (regexpr("^neg_", connection) > 0)
  
  ##
  ## Posterior connection strength
  ##
  nodenames <- rownames(unique(network))
  ll <- scores$posterior[,c(paste("pos_", nodenames, sep=''),
                            paste("neg_", nodenames, sep=''))]
  ll <- ll + scores$egeneLL
  pos <- ll - apply(ll,1,logsum)
  posMax <- apply(pos, 1, max)
  posRank <- rank(-posMax) # low numbers to low numbers
  
  
  result <- data.frame(Egene=names(scores$maxConnectionRatio),
                       connection=conn.sgene,
                       sign=conn.sign,
                       llr=scores$maxConnectionRatio,
                       llrRank=rank(-scores$maxConnectionRatio),
                       pos=posMax,
                       posRank=posRank,
                       ll=scores$egeneLL,
                       scores$posterior)
  if (is.null(o$o)) o$o <- stdout()
  write.table(result, file=o$o, quote=FALSE, sep="\t", row.names=FALSE)

  invisible() # so that the NULL return value isn't printed
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

if (Sys.getenv("RGETOPT_DEBUG") != "") {debug(main)}
main()
