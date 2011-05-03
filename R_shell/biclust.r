library(biclust)
library(Rgetopt)
source("/projects/sysbio/lab_apps/R_shell/rand_biclust.r")

#Rscript /projects/sysbio/lab_apps/R_shell/biclust_dev.R -method BCBimax -infile /projects/sysbio/map/Papers/MetaTrans/perl/temp/temp.tab -alpha 1.2 -delta 1.5 -num 50
#Rscript /projects/sysbio/lab_apps/R_shell/biclust_dev.R -method BCCC -infile /projects/sysbio/map/Papers/MetaTrans/perl/temp/temp.tab -alpha 1.2 -delta 1.5 -num 50
#Rscript /projects/sysbio/lab_apps/R_shell/biclust_dev.R -infile /projects/sysbio/map/Papers/MetaTrans/perl/temp/temp.tab
#	
# See http://cran.r-project.org/web/packages/biclust/biclust.pdf for more documentation.
# methods options:
# BCBimax
#	-minr					Minimum row size of resulting bicluster.
#	-minc					Minimum column size of resulting bicluster.
#	-num					Number of Bicluster to be found.#	-maxc					Maximum column size of resulting bicluster.
# BCCC
#	-delta					Maximum of accepted score.
#	-p						p-value to shoot for for delta selection
#	-alpha					Scaling factor.
#	-num					Number of bicluster to be found.
# BCPlaid
#	-cluster				’r’, ’c’ or ’b’, to cluster rows, columns or both (default ’b’)
#	-fit.model				Model (formula) to fit each layer. Usually, a linear model is used, that stimates three parameters: m (constant for all elements in the bicluster), a(contant for all rows in the bicluster) and b (constant for all columns). Thus, default is: y ~ m + a + b.
#	-background				If ’TRUE’ the method will consider that a background layer (constant for all rows and columns) is present in the data matrix.
#	-shuffle				Before a layer is added, it’s statistical significance is compared against a number of layers obtained by random defined by this parameter. Default is 3, higher numbers could affect time performance.
#	-iter.startup			Number of iterations to find starting values
#	-iter.layer				Number of iterations to find each layer	
#	-back.fit				After a layer is added, additional iterations can be done to refine the fitting of the layer (default set to 0)
#	-row.release			Scalar in [0,1](with interval recommended [0.5-0.7]) used as threshold to prune rows in the layers depending on row homogeneity
#	-col.release			As above, with columns
#	-max.layers				Maximum number of layer to include in the model
#	-verbose				If ’TRUE’ prints extra information on progress.
# BCQuest
#	-ns						Number of questions choosen. 
#	-nd						Number of repetitions. 
#	-sd						Sample size in repetitions. 
#	-alpha					Scaling factor for column result. 
#	-number					Number of bicluster to be found. 
#	-d						Half margin of intervall question values should be in (Intervall is mean-d,mean+d). 
#	-quant					Which quantile to use on metric data 
#	-vari					Which varianz to use for metric data
# BCSpectral
#	-normalization			Normalization method to apply to mat. Three methods are allowed as described by Kluger et al.: "log" (Logarithmic normalization), "irrc" (Independent Rescal- ing of Rows and Columns) and "bistochastization". If "log" normalization is used, be sure you can apply logarithm to elements in data matrix, if there are val- ues under 1, it automatically will sum to each element in mat (1+abs(min(mat))) Default is "log", as recommended by Kluger et al.
#	-numberOfEigenvalues	the number of eigenValues considered to find biclusters. Each row (gene) eigen- Vector will be combined with all column (condition) eigenVectors for the first numberOfEigenValues eigenvalues. Note that a high number could increase dramatically time performance. Usually, only the very first eigenvectors are used. With "irrc" and "bistochastization" methods, first eigenvalue contains background (irrelevant) information, so it is ignored.#	-minr					minimum number of rows that biclusters must have. The algorithm will not consider smaller biclusters.#	-minc					minimum number of columns that biclusters must have. The algorithm will not consider smaller biclusters.#	-withinVar				maximum within variation allowed. Since spectral biclustering outputs a checker- board structure despite of relevance of individual cells, a filtering of only relevant cells is necessary by means of this within variation threshold.
# BCXmotifs
#	-ns						Number of rows choosen.
#	-nd						Number of repetitions.
#	-sd						Sample size in repetitions.
#	-alpha					Scaling factor for column result.
#	-number					Number of bicluster to be found.
#default parameters here:



parse_args <- function(argv)
{	
	flags <- c('-background', '-verbose')
	string_parameters <- c('-infile', '-method', '-cluster', '-fit.model', '-normalization')
	numeric_parameters <- c('-alpha', '-back.fit', '-col.release', '-d', '-delta', '-iter.layer', '-iter.startup', '-max.layers', '-maxc', '-minc', '-minr', '-nd', '-ns', '-num', '-numberOfEigenvalues', '-p', '-quant', '-row.release', '-sd', '-shuffle', '-vari', '-withinVar')

	#default method: BCCC
	method <- "BCCC"
	
	#search for the method, to allow for setting defaults
	for(i in 1:length(argv))
	{
		if(argv[i] == "-method")
		{
			method <- argv[i+1]
		}
	}
	
	#set defaults for selected method
	switch(tolower(method), 
		"bcbimax"		= input <- list( '-method'='BCBimax', '-minr'=1, '-minc'=1, '-num'=100, '-maxc'=1000 ),
		"bccc"			= input <- list( '-method'='BCCC', '-alpha'=1.2, '-p'=.05, '-num'=100 ),
		"bcplaid"		= input <- list( '-method'='BCPlaid', '-cluster'='b', '-fit.model'='y ~ m + a + b', '-background'=TRUE, '-shuffle'=3, '-iter.startup'=5, '-iter.layer'=10, '-back.fit'=0, '-row.release'=.7, '-col.release'=.7, '-max.layers'=20, '-verbose'=FALSE  ),
		"bcquest"		= input <- list( '-method'='BCQuest', '-ns'=10, '-nd'=10, '-sd'=5, '-alpha'=.05, '-number'=100, '-d'=1, '-quant'=.25, '-vari'=1  ),
		"bcspectral"	= input <- list( '-method'='BCSpectral', '-normalization'='log', '-numberOfEigenvalues'=3, '-minr'=2, '-minc'=2, '-withinVar'=1 ),
		"bcxmotifs"		= input <- list( '-method'='BCXmotifs', '-ns'=10, '-nd'=10, '-sd'=5, '-alpha'=.05, '-number'=100 )
		)

	for(i in 1:length(argv))
	{
		#set flags (boolean parameters) to TRUE if specified
		for(j in 1:length(flags))
		{
			if( argv[i] == flags[j] )
			{
				input[flags[j]] = TRUE
				next
			}
		}

		#parse argument array for values
		for(j in 1:length(string_parameters))
		{
			if( argv[i] == string_parameters[j] )
			{
				input[string_parameters[j]] = argv[i+1]
				next
			}
		}

		#parse argument array for values
		for(j in 1:length(numeric_parameters))
		{
			if( argv[i] == numeric_parameters[j] )
			{
				input[numeric_parameters[j]] = as.numeric(argv[i+1])
				next
			}
		}
	}
	return(input)
}


args <- commandArgs(TRUE)
if( length(args) == 0 ) { cat("Must supply arguments\n"); quit() }

input <- parse_args(args)

#check for required parameters:
if( is.null(input[["-infile"]]) ) { cat("Must supply an input file\n"); quit() }

#read in the input file (pRF written by Charlie)
infile <- parseReadableFile(input[["-infile"]])

header <- strsplit(readLines(con=infile, n=1), "\t")[[1]]

data <- read.delim(infile, header=FALSE, row.names=NULL, stringsAsFactors=FALSE)

if( (tolower(input[["-method"]])=="bccc") && is.null(input[["-delta"]]) )
{
	input["-delta"] <- giveDelta(as.matrix(data[,-1]), pval=input[["-p"]])
}

	
sink(stderr()) # biclust() is noisy and prints to stdout

switch(tolower(input[["-method"]]), 
							"bcbimax"		= s <- attributes(biclust(as.matrix(data[,-1]), method=BCBimax(), minr=input[["-minr"]], minc=input[["-minc"]], num=input[["-num"]], maxc=input[["-maxc"]] ) ) ,
							"bccc"			= s <- attributes(biclust(as.matrix(data[,-1]), method=BCCC(), delta=input[["-delta"]], alpha=input[["-alpha"]], number=input[["-num"]])),
							"bcplaid"		= s <- attributes(biclust(as.matrix(data[,-1]), method=BCPlaid(), cluster=input[["-cluster"]], fit.model=input[["-fit.model"]], background=input[["-background"]], shuffle=input[["-shuffle"]], iter.startup=input[["-iter.startup"]], iter.layer=input[["-iter.layer"]], back.fit=input[["-back.fit"]], row.release=input[["-row.release"]], col.release=input[["-col.release"]], max.layers =input[["-max.layers"]], verbose=input[["-verbose"]] )),
							"bcquest"		= s <- attributes(biclust(as.matrix(data[,-1]), method=BCQuest(), ns=input[["-ns"]], nd=input[["-nd"]], sd=input[["-sd"]], alpha=input[["-alpha"]], number=input[["-num"]], d=input[["-d"]], quant=input[["-quant"]], vari=input[["-vari"]] )),
							"bcspectral"	= s <- attributes(biclust(as.matrix(data[,-1]), method=BCSpectral(), normalization=input[["-normalization"]], numberOfEigenvalues=input[["-numberOfEigenvalues"]], minr=input[["-minr"]], minc=input[["-minc"]], withinVar=input[["-withinVar"]] )),
							"bcxmotifs"		= s <- attributes(biclust(as.matrix(data[,-1]), method=BCKmotifs(), ns=input[["-ns"]], nd=input[["-nd"]], sd=input[["-sd"]], alpha=input[["-alpha"]], number=input[["-num"]] ))
							)

#if(input[["-method"]] == "BCCC")
#{
#	s <- attributes(biclust(as.matrix(data[,-1]), method=input[["-method"]], delta=input[["-delta"]], alpha=input[["-alpha"]], number=input[["-num"]]))
#}	

sink(NULL)
warnings()

ColXClust <- apply( s$NumberxCol, 1, function(a){ tmp <- header[-1]; tmp[a] } )
RowXClust <- apply( s$RowxNumber, 2, function(a){ tmp <- data[1]; tmp[a,] } )	

for(i in 1:length(RowXClust))
{
	cat(paste(">", i, "\n"))
	cat(RowXClust[[i]], file="", sep="\t")
	cat("\n")
	cat(ColXClust[[i]], file="", sep="\t")
	cat("\n")
}
