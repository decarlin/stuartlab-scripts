scatter.prepplot <-
function(argv) {
  result <- list()

  argspec <- c(paste(global.options[1], "Module scatter - make scatter plots

The plotting character can either be a single character, or 's' followed
by an integer in order to specify an R symbol. Type 'example(points') in
R to see all symbols.  Commonly used symbols are s1 for open circle, and
s19 for a filled circle.

Module Options:", sep="\n"),
               "x=i        column for x-axis location (required)",
               "y=i        column for y-axis location (required)",
               "type=s     type of plot, from plot.default.  Defaults to 'p', points",
               "err|e=li   column(s) for error bars. If two first the amount up from the point, then the amount down from the point.",
               "errtick=f  width of error bars (inches in figure) ",
               "noframe    omit the border box and axis labels",
               "lty=i      line type (see par())",
               "lwd=f      line width",
               "pch=s      default plot character",
               "pchcol=i   column for plot character",
               "cex=f      default plot character size (1 is default, <1 is smaller, >1 is bigger",
               "cexcol=i   column for plot character size",
               "color=s    default color for plotted points",
               "colorcol=i colmun for specifying point color",
               datafile.options)
  o <- Rgetopt(argspec=argspec, argv=argv)
  
  ## Get Data File
  if (length(o$argv) != 1) {
    usage("Need a file for input", argspec)
  }
  df <- getTabFile(o$argv, o)
  
  xcol <- o$x
  ycol <- o$y

  if (is.null(xcol)) usage("Must specify a column for x-values", argspec)
  if (is.null(ycol)) usage("Must specify a column for y-values", argspec)
  checkNumericCols(df, c(xcol,ycol), o$argv)
  
  x <- df[,xcol]
  y <- df[,ycol]
  
  result$xlim <- range(x,na.rm=T)
  result$ylim <- range(y,na.rm=T)

  eup <- edown <- NULL
  if (is.null(o$err)) {
    NULL
  } else {
    if (length(o$err) > 2) usage("Too many error columns", argspec)
    checkNumericCols(df, o$err, o$argv)
    eup <- y + df[,o$err[1]]
    edown <- y - df[,o$err[length(o$err)]]
    if (is.null(o$errtick)) o$errtick <- 0.25
  }

  ## Deal with the plot character.  Since I don't know of anyway of having
  ## both integers and character strings in the pch of the plot,
  ## we have to split it up into two separate plots
  pch.default <- if (is.null(o$pch)) "s1" else o$pch
  pch <- if (is.null(o$pchcol)) rep(pch.default, length(x)) else {
    checkColsExist(df, o$pchcol, o$argv)
    as.character(df[,o$pchcol])
  }
  
  is.symbol <- (nchar(pch) > 1) & (substr(pch,1,1) == 's')
  pch.symbol <- suppressWarnings(as.integer(substr(pch,2,nchar(pch))))
  if (any(is.na(pch.symbol[is.symbol]) & !is.na(pch[is.symbol]))) {
    bad <- which(is.na(pch.symbol[is.symbol]) & !is.na(pch[is.symbol]))
    warning("Not plotting", length(bad), "points due to malformed symbol,",
            "for example:", pch[is.symbol][bad[1]])
  }
  if (any(nchar(pch[!is.symbol]) > 1)) {
    bad <- which(nchar(pch[!is.symbol]) > 1)
    warning("Only using the first character for ", length(bad), "points.",
            "Example pch specifcation: ", pch[!is.symbol][bad[1]])
  }

  ## point size and color
  cex.default <- if (is.null(o$cex)) 1 else (o$cex)
  cex <- if (is.null(o$cexcol)) rep(cex.default, length(x)) else {
    checkNumericCols(df, o$cexcol, o$argv)
    cex <- df[, o$cexcol]
  }
  cex[is.na(cex)] <- cex.default
  color.default <- if (is.null(o$color)) "black" else (o$color)
  color <- if (is.null(o$colorcol)) rep(color.default, length(x)) else {
    checkColsExist(df, o$colorcol, o$argv)
    color <- as.character(df[,o$colorcol])
  }
  color[nchar(color) == 0] <- color.default
  
  result$plotFun <- function() {
    if (is.null(o$type)) o$type <- 'p'
    points(x[is.symbol],  y[is.symbol],  pch=pch.symbol[is.symbol], lty=o$lty,
           col=color[is.symbol],  cex=cex[is.symbol], type=o$type, lwd=o$lwd)
    points(x[!is.symbol], y[!is.symbol], pch=pch[!is.symbol], lty=o$lty,
           col=color[!is.symbol], cex=cex[!is.symbol], type=o$type, lwd=o$lwd)
    if(is.null(o$noframe)) {
      axis(1);
      axis(2);
      box();
    }
    if (!is.null(o$err)) {
      arrows(x, eup, x, edown, angle=90, code=3, length=o$errtick)
    }
  }
  return(result)
}
