#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("wilcox.R - perform a 2-sample Wilcoxon (i.e. Mann-Whitney)
           test on every row of a tab-delimited file.
Usage:
        wilcox.R -x cols -y cols [options] data.tab

Options:",
             "x=li        columns for sample 1",
             "y=li        columns for sample 2",
             "a=s         alternative (defaults to two.sided)",
             "outcols=li  columns to be output as as names (defaults to 1)",
             "padjust=s   pvale adjustment (see p.adjust, default is none)")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(a="two.sided", outcols=1, padjust="none"))

  if (any(length(o$argv) != 1, is.null(o$x), is.null(o$y))) {
    usage("Need exactly one file argument, two column specifiers (see --help)")
  }

  d <- readTabFile(o$argv[1])
  rownames(d) <- NULL

  pv <- apply(d, 1, function(v) {
    x <- as.numeric(v[o$x])
    y <- as.numeric(v[o$y])
    w <- wilcox.test(x, y, alternative=o$a)
    return(w$p.value)
  })

  pv <- p.adjust(pv, o$padjust)

  write.table(cbind(d[,o$outcols,drop=F],p.value=pv), file = stdout(), 
              sep = "\t", row.names = F, quote = F)
}

main()
