#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("nmf.R - approximate a non-negative matrix factorization.
For an n by m matrix M , it finds a n by r matrix W and an r by n matrix H
such that M ~ W * H.  By default, r will be set equal to m. 
Usage:
  nmf.R [options] -W w.tab -H h.tab input.tab

Options:",
             "W=wf    where to save the matrix W",
             "H=wf    where to save the matrix H",
             "r=i     factorization dimensionality. defaults to ncol(M)",
             "header=i     header lines (defaults to 1)")

nmf <- function (m, r=ncol(m), tol= 0.0001*prod(dim(m)), max.iter=10000,
                 w=NULL, h=NULL, rownorm=TRUE, start.with.h=FALSE) {
  res <- double(length=max.iter)
  cnames <- cnames <- paste("Comp", 1:r, sep="")

  if (is.null(w) || nrow(w) != nrow(m) || ncol(w) != r) {
    w <- matrix(rgamma(nrow(m) * r, shape=3), ncol = r)
    colnames(w) <- cnames
    rownames(w) <- rownames(m)
  }

  if (is.null(h) || nrow(h) != r || ncol(h) != ncol(m)) {
    h <- matrix(rgamma(r * ncol(m), shape=3), nrow = r)
    rownames(h) <- cnames
    colnames(h) <- colnames(m)
  }

  if (start.with.h) {
    h <- h * ( (t(w) %*% m) / (t(w) %*% w %*% h) )
  }

  preverr <- Inf
  for (i in 1:max.iter) {
    w <- w * ( (m %*% t(h)) / (w %*% h %*% t(h)) )
    w <- apply(w, 2, function(x) { x / sum(x) })
    # now use this new h
    h <- h * ( (t(w) %*% m) / (t(w) %*% w %*% h) )

    resid <- as.vector(m - (w %*% h))
    res[i] <- sum(resid * resid)
    if ((res[i] <= tol) || (res[i]/preverr > 0.99999)) {
      res <- res[1:i]
      break
    }
    preverr <- res[i]
  }
  if (length(res) == max.iter) {
    warning("Reached maximum iterations")
  }

  if (rownorm) {
    rs <- apply(h, 1, max)
    return(list(w=w,#t(apply(w, 1, "*", y = rs)),
                h=h,#apply(h, 2, "/", y = rs),
                rs=rs,
                res=res,
                iter=length(res)))
  } else {  
    return(list(w=w, h=h, iter=length(res)))
  }
}

write.matrix <- function(x, file, sep="\t", ...) {
  x.df <- if (is.null(rownames(x))) x else data.frame(rowname=rownames(x), x)
  write.table(x.df, file=file, sep=sep, row.names=FALSE, quote=FALSE)
}

main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]

  o <- Rgetopt(argv=argv, argspec=argspec, defaults=list(header=1))

  

  if (is.null(o$W)) {
    usage("option -W is required", argspec)
  }

  if (is.null(o$H)) {
    usage("option -H is required", argspec)
  }

  if (length(o$argv) != 1) {
    usage("Need a file argument", argspec)
  }

  M.df <- read.delim(o$argv[1], check.names=F, skip=max(0, o$header - 1),
                     header=(o$header > 0), row.names=NULL)

  if (is.numeric(M.df[[1]])) {
    M <- as.matrix(M.df)
  } else {
    M <- as.matrix(M.df[,2:ncol(M.df)])
    rownames(M) <- M.df[[1]]
  }


  if (is.null(o$r)) o$r <- ncol(M)

  result <- nmf(M, r=o$r)

  cat(paste("Completed in", result$iter, "iterations\n"))
  write.matrix(result$w, file=o$W)
  write.matrix(result$h, file=o$H)
}


main()
