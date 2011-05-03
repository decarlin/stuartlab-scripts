#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("noise.R - add Gaussian noise to numeric values in a tab delimited file",
             "sd=f       standard deviation of noise (default 1)",
             "h=i        number of header lines in file (default 1)",
             "a=i        number of annotation columns in file (default 1)",
             "k=li       limit noise addition to only columns k",
             "d=s        delimiter string between fields (default tab)")

default.options <- list(sd=1, h=1, a=1, d="\t")

readHeadedFile <- function(file, headerlines, delim="\t") {
  if (!isOpen(file)) {
    open(file) # readLines will close any file handle if it has to open it
               # this is problematic for stdin
  }

  header <- readLines(file, n=headerlines)
  header.parsed <- sapply(header, function(l) strsplit(l, delim)[[1]])
  names(header.parsed) <- NULL

  data <- read.table(file, sep=delim, stringsAsFactors=FALSE, quote="",
                     row.names=NULL, header=FALSE, skip=0)
  return(list(header=header, data=data, header.parsed=header.parsed))
}

main <- function() {
  o <- Rgetopt(argspec, defaults=default.options)
  
  if (length(o$argv) != 1) {
    print(o)
    usage("Must specify a single file argument", argspec)
  }
  file.connection <- parseReadableFile(o$argv)
  d <- readHeadedFile(file.connection, o$h, o$d)
  
  if (is.null(o$k)) {
    o$k <- (o$a + 1):ncol(d$data)
  }
  
  m <- d$data[,o$k]
  
  d$data[,o$k] <- m + rnorm(prod(dim(m)), sd=o$sd)
  
  writeLines(d$header)
  write.table(d$data, file=stdout(), quote=F, sep=o$d,
              row.names=F, col.names=F)
}

main()
