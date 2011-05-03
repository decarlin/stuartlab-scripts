#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("anova.R - run one way ANOVA on each row of a tab file.  The
first row should specify the factor.",
             "delim=s   header delimiter")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(delim="\t"))
  if (length(o$argv) != 1) {usage("must specify a file")}

  f <- parseReadableFile(o$argv)
  if (!isOpen(f)) open(f)
  facline <- readLines(f, n=1)

  fac <- as.factor(strsplit(facline, o$delim)[[1]][-1])
  
  df <- readTabFile(f, hlines=0, delim=o$delim)
  d <- as.matrix(df[,-1])
  stopifnot(is.numeric(d))
  rownames(d) <- df[,1]

  rowAnova <- function(x) {
    tryCatch(a <- summary(aov(x ~ fac))[[1]],
             error=function(e) a <<- rep(NA,10),
             finally=)
    return(unlist(a)[c(1:7,9)])
  }
  result <- t(apply(d, 1, rowAnova))

  colnames(result) <- c("Df1", "Df2", "Sum Sq1", "Sum Sq2", "Mean Sq1",
                        "Mean Sq2", "F value1", "Pr(>F)1")
  writeTabFile(result, file=stdout())
  invisible()
}

main()
