rand_biclust <- function(datMat, minsize=6, maxsize=10)
{
	Rows<-floor(runif(floor(runif(1,min=minsize,max=maxsize+1)),1, dim(datMat)[1]+1))
	Cols<-floor(runif(floor(runif(1,min=minsize,max=maxsize+1)),1, dim(datMat)[2]+1))

	return(datMat[Rows,Cols])
}

computeH <- function(cluster)
{
	colAve <- matrix(1,dim(cluster)[1],dim(cluster)[2])*apply(cluster,1,mean)
	rowAve <- t(apply(cluster,2,mean)*t(matrix(1,dim(cluster)[1], dim(cluster)[2])))
	allAve <- mean(cluster)*matrix(1,dim(cluster)[1],dim(cluster)[2])
	H <- (1/(dim(cluster)[1]*dim(cluster)[2]))*sum((cluster-rowAve-colAve+allAve)^2)
	return(H)
}

giveDelta <- function(datMat,pval=0.05, ntrials=100000)
{
	Hs<-c()

	for(i in 1:ntrials)
	{
		num<-computeH(rand_biclust(datMat))
		Hs[i]<-num
	}

	Hs<-sort(Hs)
	return(Hs[floor(pval*ntrials)])

}	