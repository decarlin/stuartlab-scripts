`bars.prepplot` <-
function(argv) {
  result <- list()

  argspec <- c(paste(global.options[1], "Module bars - make a barplot
module options:", sep="\n"),
               "data|d=li     data columns",
               "x=i           column for x-axis locations", 
               "err|e=li      error columns",
               "labels|l=i    label column",
               "gap|g=f       minimum group gap as fraction of bar width",
               "palette|p=s   palette, from RColorBrewer",
               "colors=ls     colors for the plot",
               datafile.options)
  o <- Rgetopt(argspec=argspec, argv=argv)
  
  ## Get Data File
  if (length(o$argv) != 1) {
    usage("Need a file for input", argspec)
  }
  df <- getTabFile(o$argv, o)
  
  ## Parse data file
  dcols <- if (is.null(o$data)) {
    if (ncol(df) == 1) 1 else 2
  } else o$data
  checkNumericCols(df, dcols, o$argv)
  d <- t(df[,dcols])
  
  ecols <- if (is.null(o$err)) {
    if (is.null(o$data)) (dcols + 1)
    else NULL
  } else o$err
  e <- eup <- edown <- ecols.real <- NULL
  if (!is.null(ecols)) {
    if (length(ecols) != length(dcols))
    usage("Must specify the same number of error bar columns as data columns.
Use NA to specify no error bars for a data column.", argspec)
    ecols.real <- ecols[!is.na(ecols)]
    checkNumericCols(df, ecols.real, o$argv)
    e <- t(df[,ecols.real])
    eup <- d[!is.na(ecols),] + e
    edown <- d[!is.na(ecols),] - e
  }

  lblcol <- if(is.null(o$labels)) {
    if (is.null(o$data) && ncol(df) > 1) 1
    else NULL
  } else o$labels
  checkColsExist(df, lblcol, o$argv)
  labels <- character(0)
  if (!is.null(lblcol)) {
    labels <- df[,lblcol]
  }

  ## Set plot options
  palette <- if (is.null(o$palette)) "Pastel1" else o$palette

  colors <- if(is.null(o$colors))
    brewer.pal(max(3,length(dcols)), palette)[1:length(dcols)]
  else
    o$colors

  result$plotAdjust <- list()
  if (!is.null(lblcol)) {
    southMargin <- max(strwidth(df[[lblcol]], units="inches")) +
      par("csi")*par("mgp")[2]
    mai <- par("mai")
    mai[1] <- southMargin
    result$plotAdjust$mai <- mai
  }

  ## Munge data for plotting
  x <- 1:nrow(df)
  xdiff <- diff(x)

  gap <- if(is.null(o$gap)) 0.2 else o$gap
  groupwidth.bars <- nrow(d) + gap
  barwidth <- 1/groupwidth.bars * min(xdiff)

  space <- d; space[] <- 0
  xstartadjust <- (groupwidth.bars)*barwidth
  if (nrow(d) == 1) xstartadjust <- xstartadjust / 2
  space[1,] <- c(x[1]/barwidth - xstartadjust, gap*xdiff/min(xdiff))

  result$plotFun <- function() {
    midpoints <- barplot(d, space=space, beside=T, width=barwidth,
                         names.arg=rep('', ncol(d)), col=colors, add=T, las=3)
    oldmgp <- mgp <- par("mgp")
    mgp[2:3] <- 0
    par(mgp=mgp)
    if (length(labels) > 0) {
      axis(side=1, at=colMeans(midpoints), labels=labels, tick=F, las=3)
    }
    par(mgp=oldmgp)
    if (!is.null(ecols)) {
      e.x <- midpoints[!is.na(ecols),]
      usr <- par("usr"); pin <- par
      xconv <- 
      alength <- min(diff(sort(e.x))) / 4 *
        (par("pin")[1] / diff(par("usr")[1:2]) )
      arrows(e.x, eup, e.x, edown, angle=90, code=3, length=alength)
    }
  }

  result$ylim <- range(0,d,eup,edown,na.rm=T)
  pad <- barwidth/2
  result$xlim <- range(x - pad, x + pad)

  return(result)
}

