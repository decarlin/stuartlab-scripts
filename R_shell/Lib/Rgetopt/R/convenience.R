readTabFile <- function(filename, delim="\t", hlines=1, ...) {
  skip <- max(0, hlines - 1)

  if (is.character(filename)) {
    f <- parseReadableFile(filename)
  } else {
    f <- filename
  }

  if(!isOpen(f)) open(f)

  d <- read.delim(f, sep=delim,
                  row.names=NULL,
                  header=(hlines > 0),
                  skip=skip,
                  check.names=FALSE,
                  quote="", 
                  stringsAsFactors=FALSE,
                  ...)
  if(isOpen(f)) close(f)
  return(d)
}

writeTabFile <- function(x, file='', delim="\t", upperLeftText="Key", ...) {
  if (!is.null(rownames(x))) {
    x <- data.frame(rownames(x), x, check.names=FALSE)
    if (!is.null(colnames(x))) {
      colnames(x)[1] <- upperLeftText
    }
  }
  write.table(x, file=file, sep=delim, row.names=F, quote=F,
              col.names=!is.null(colnames(x)), ...)
}
