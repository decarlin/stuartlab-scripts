#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("disc.R - discretize",
             "boundaries|b=lf  discretization boundaries",
             "labels|l=ls      labels for output")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec)

  if (length(o$argv) != 1) {
    usage("Must have exactly one file", argspec)
  }
  in.file <- parseReadableFile(o$argv)

  if (is.null(o$boundaries)) usage("Must specify boundaries", argspec)
  if (is.null(o$labels)) usage("Must specify labels", argspec)
  if (length(o$labels) != length(o$boundaries) + 1) {
    usage("must have one more label than number of boundaries", argspec)
  }

  if (!all(o$boundaries == sort(o$boundaries))) {
    usage("boundaries are not in sorted order", argspec)
  }

  discmap <- function(x) {
    if (!is.numeric(x)) return(x)
    index <- rowSums(sapply(o$boundaries, function(b) x > b)) + 1
    return(o$labels[index])
  }

  df <- read.delim(in.file, header=T, stringsAsFactors=FALSE,
                   check.names=FALSE)

  df.disc <- data.frame(lapply(df, discmap),
                        check.names=FALSE, stringsAsFactors=FALSE)

  write.table(df.disc, file=stdout(), sep="\t", quote=FALSE, row.names=FALSE,
              col.names=TRUE)
}

main()
