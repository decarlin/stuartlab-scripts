#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("blank_smaller_entry.R - ",
             "text=s   text to replace smaller entries with (default: NA)")

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(text="NA"))

  stopifnot (length(o$argv) == 2)

  a.df <- readTabFile(o$argv[1])
  b.df <- readTabFile(o$argv[2])

  stopifnot(dim(a.df) == dim(b.df))

  for (i in 1:ncol(a.df)) {
    if (is.numeric(a.df[[i]]) && is.numeric(b.df[[i]])) {
      a <- as.character(a.df[,i])
      a[a.df[,i] < b.df[,i]] <- o$text
      a.df[,i] <- a
    }
  }
  write.table(a.df, file=stdout(), sep="\t", quote=F, row.names=F)
}

main()
