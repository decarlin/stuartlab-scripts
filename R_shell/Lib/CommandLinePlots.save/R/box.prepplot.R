`box.prepplot` <-
function(argv) {
  result <- list()
  argspec <- c(paste(global.options[1], "Module box - make a box on the plot
Syntax:
... box [options] x1 y1 x2 y2
Options:"),
               "color|c=s    fill color",
               "border|b=s   border color",
               "line|l=i     line style (see lty in par)")

  o <- Rgetopt(argspec=argspec, argv=argv)
  if (length(o$argv) != 4) {
    usage("Must specify four arguments.", argspec)
  }
  coords <- lapply(o$argv, parseFloat)
  if (any(sapply(coords, is.null))) {
    usage(paste("Couldn't parse floats from: ", o$argv, collapse=" "), argspec)
  }
  col <- if(is.null(o$color)) NA else o$color
  border <- if (is.null(o$border)) "black" else o$border
  lty <- if (is.null(o$line)) 1 else o$line
  
  result$plotFun <- function() {
    rect(coords[[1]], coords[[2]], coords[[3]], coords[[4]],
         col=col, border=border, lty=lty)
  }
  return(result)
}

