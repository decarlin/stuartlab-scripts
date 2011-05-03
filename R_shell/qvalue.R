#!/usr/bin/env Rgetopt.py
library(Rgetopt)

## qvalue will try to open an X connection, causing an error
Sys.setenv(DISPLAY='')
sink(file('/dev/null', open="w"), type="message") # qvalue is noisy
library(qvalue)
sink()

argspec <- c("qvalue.R - read in p-values, and use the Storey method to calculate q-values.
The specified columns are taken as a single group of p-values from which to estimate q-values.
Usage:
    qvalue.R [options] inputfile",
             "h=i          header lines (default 1)",
             "k=li         columns with p-values",
             "lambda=lf    which lambdas to use for pi0 estimation",
             "log=f        p-values are supplied with this log base")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(h=1, lambda=seq(0,0.9,0.05)))

  if (length(o$argv) != 1) {
    usage("Must have exactly one file argument", finish=q(status=1))
  }

  if (is.null(o$k)) {
    usage("Must specify columns for p-values", finish=q(status=1))
  }

  df <- readTabFile(o$argv, hlines=0)

  if (!all(o$k > 0, o$k <= ncol(df))) {
    usage("argument -k outside range of data", finish=q(status=1))
  }

  rows <- 1:nrow(df) > o$h

  pv <- as.numeric(as.vector(df[rows,o$k]))
  pv.missing <- is.na(pv)
  pv.filtered <- pv[!pv.missing]
  if (length(pv.filtered) == 0) {
    usage("no parseable p-values")
  }

  if (!is.null(o$log)) {
    pv.filtered <- o$log^pv.filtered
  }

  if (any(pv.filtered < 0, pv.filtered > 1)) {
    stop("Negative p-value, or p-value greater than one specified")
  }

  qv.obj <- qvalue(pv.filtered, lambda=o$lambda)

  pv[!pv.missing] <- qv.obj$qvalues

  df[rows,o$k] <- pv

  write.table(df, file=stdout(), sep="\t", row.names=F, quote=F, col.names=F)
}

if (Sys.getenv("RGETOPT_DEBUG") != "") {debug(main)}
main()
