#!/usr/bin/env Rgetopt.py
library(Rgetopt)

argspec <- c("cuttree.R - cut a hierachical clustering from Eisen Cluster
Be sure to specify .cdt on the end of the clustering filename, and make sure
that both the .cdt and .gtr files are there.

The .gtr file must have the SAME NAME as the .cdt file, excepting the extention.
You do NOT specify the .gtr file manually--it is found based on the .cdt filename.

WARNING: this program is pretty hackish for a .R script, and that's saying a
lot.  Be sure to sanity check your results.

Example:

    cuttree.R  -k 10  myClusterFile.cdt
         (assumes that myClusterFile.gtr is in the same directory as the .cdt)
    This will cut the tree such that it gives you 10 clusters (-k 10).

Usage:
    cuttree.R [-h height|-k number_clusters] YOUR_CLUSTER_FILE.cdt",
             "k=i   number of clusters",
             "h=f   tree height to cut")
## Alex's Note: the Usage part IS NOT FREE TEXT even though it looks like it.
## It actually tells Charlie's Rgetopt what options are valid! DO NOT CHANGE IT without knowing what you are doing!!!

### ============================================================
main <- function(argv) {
  if (missing(argv)) argv <- RgetArgvEnvironment()[-1]
  o <- Rgetopt(argv=argv, argspec=argspec) ## Get command line options. This is Charlie's special "Rgetopt" library (not part of standard R)
  
  if (length(o$argv) == 0) {
    usage("ERROR IN INPUT: You must specify a .cdt file.", argspec=argspec)
  }
  if (length(o$argv) > 1) {
    stop("ERROR IN INPUT: Too many input files specified, must only have the single .cdt file!")
  }
  cdtInputFile <- o$argv[1]

  if (is.null(o$k) && is.null(o$h)) {
    stop("ERROR IN INPUT: neither -h or -k set. Set either -h to cut at a specific height, or -k to cut into a certain number of subtrees.")
  }

  dump <- function(x,f=stdout()) {
    write.table(x,file=f,sep="\t",col.names=FALSE,quote=FALSE)
  }

  gtrTreeFile <- paste(substr(cdtInputFile, 1, nchar(cdtInputFile)-4), ".gtr", sep='') ## <-- get the gtr filename by stripping the ".cdt" off the cdt file (actually strips off the last four characters) and then appending .gtr

  hier <- read.cdt.tree(cdt.file=cdtInputFile, tree.file=gtrTreeFile)
  
  if (is.null(o$h)) { ## if the user did NOT specify the height...
    dump(cutree(hier, k=o$k)) ## ...then call cutree with a certain number of breaks (k = something)
  } else {
    dump(cutree(hier, h=o$h)) ## ... otherwise call cutree with a certain height cutoff (h = height cutoff)
  }
}

# Need three attributes: merge, height, and labels
#  This should hopefully be easy....
#
# What still needs to be done when I have more time:  read in cdt data,
#  and also array tree

### ============================================================
read.cdt.tree <- function(tree.file, cdt.file, cdt.headerlines=3){
  tree.data <- read.delim(tree.file, header=FALSE)
  
  merge.labels <- tree.data[,1]
  
  gene.labels <- system(paste("cut -f1", cdt.file), intern=TRUE)
  gene.labels <- gene.labels[-(1:cdt.headerlines)]
  pretty.labels <- system(paste("cut -f2", cdt.file), intern=TRUE)
  pretty.labels <- pretty.labels[-(1:cdt.headerlines)]
  
  get.tree.index <- function(x, neg, pos) {
    nm <- -match(x, neg)
    pm <- match(x, pos)
    
    if(any(is.na(nm) == is.na(pm))) {
      stop("overlapping gene and node names")
    }
    pm[is.na(pm)] <- nm[!is.na(nm)]
    return(pm)
  }
  merge.col1 <- get.tree.index(tree.data[,2], gene.labels, merge.labels)
  merge.col2 <- get.tree.index(tree.data[,3], gene.labels, merge.labels)

  list(merge=cbind(merge.col1, merge.col2),
       labels=pretty.labels,
       height=(1-tree.data[,4])) # this is for Pearson correlation...
}


### ============================================================
read.cluster.tree <- function(tree.file, gene.labels, pretty.labels) {
  tree.data <- read.delim(tree.file, header=FALSE)
  merge.labels <- tree.data[,1]
  
  get.tree.index <- function(x, neg, pos) {
    nm <- -match(x, neg)
    pm <- match(x, pos)
    
    if(any(is.na(nm) == is.na(pm))) stop("FATAL ERROR: overlapping gene and node names")
    pm[is.na(pm)] <- nm[!is.na(nm)]
    return(pm)
  }
  merge.col1 <- get.tree.index(tree.data[,2], gene.labels, merge.labels)
  merge.col2 <- get.tree.index(tree.data[,3], gene.labels, merge.labels)

  list(merge=cbind(merge.col1, merge.col2),
       labels=pretty.labels,
       height=tree.data[,4]) # return a three-element list with data and labels
}



### ============================================================
main() # <-- finally call the main function!

