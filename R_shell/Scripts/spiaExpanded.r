spiaExpanded = function (de = NULL, refGenes = NULL, organism = "hsa", nBoots = 2000, plots = FALSE, verbose = TRUE, betaCoefs = NULL) 
{
##################################################
#
# de       - A named vector containing log2 fold-changes of the
#            differentially expressed genes. The names of this numeric
#            vector are Entrez gene IDs 
# refGenes - A vector with the Entrez gene IDs in the reference
#            set. If the data was obtained from a microarray
#            experiment, this set will contain all  genes present on
#            the specific array used for the experiment. This vector
#            should contain all names of the `de' argument. 
# organism - A three letter character array designating the organism.
#            Default is "hsa", Homo sapiens.
# nBoots   - Number of bootstrap iterations used to compute the pPERT
#            value (probablity of perterbation). Should be larger than
#            100, recommended 2000. 
# 
##################################################
# REFACTORING NOTES - May 2009
#  This code was refactored by Dent Earl, dearl @ soe ucsc edu
#  The intention was to make the method explicit where it had
#  been obfuscated. The hope is that the refactored code can provide the
#  basis for a port from R into C.
#
##################################################
cat("Dent Version 0.2\n")
##################################
# INITIAL CHECKS OF de AND refGenes 
    if (is.null(de) | is.null(refGenes)) {
        stop("`de' and `refGenes' arguments can not be NULL!")
    }
    IDsNotPresent = names(de)[!names(de) %in% refGenes]
    if (length(IDsNotPresent)/length(de) > 0.01) {
        stop("More than 1% of your `de' genes have IDs are not present in the `refGenes' reference array! Are you sure you use the right `refGenes' reference array?")
    }
    if (length(IDsNotPresent) > 0) {
        cat("The following IDs are missing from `refGenes' vector...:\n")
        cat(paste(IDsNotPresent, collapse = ","))
        cat("\nThey were added to your universe...")
        refGenes = c(refGenes, IDsNotPresent)
    }
    if (length(intersect(names(de), refGenes)) != length(de)) {
        stop("`de' must be a vector of log2 fold changes. The names of `de' should be included in the reference array!")
    }
#
##################################################
    relationships = c("activation", "compound", "binding/association",  
        "expression", "inhibition", "activation_phosphorylation", 
        "phosphorylation", "indirect", "inhibition_phosphorylation", 
        "dephosphorylation_inhibition", "dissociation", "dephosphorylation", 
        "activation_dephosphorylation", "state", "activation_indirect", 
        "inhibition_ubiquination", "ubiquination", "expression_indirect", 
        "indirect_inhibition", "repression",
        "binding/association_phosphorylation",  
        "dissociation_phosphorylation", "indirect_phosphorylation")
    if (is.null(betaCoefs)) {
        betaCoefs = c(1, 0, 0, 1, -1, 1, 0, 0, -1, -1, 0, 0, 1, 0, 
            1, -1, 0, 1, -1, -1, 0, 0, 0)
        names(betaCoefs) = relationships
    } else {
        if (!refGenes(names(betaCoefs) %in% relationships)) {
            stop(paste("betaCoefs (beta coefficients) must be a numeric vector of length", 
                length(relationships), "with the following names:", "\n", 
                paste(relationships, collapse = ",")))
        }
    }
    .myDataEnv = new.env(parent = emptyenv())
    ########################################
    # LOAD IN ORGANISMS PATHWAY DATA IF LOCAL, OR DOWNLOAD DATA IF NOT FOUND LOCALLY
    datload = paste(organism, "SPIA", sep = "")
    if (!paste(datload, ".RData", sep = "") %in% dir(system.file("data", package = "SPIA"))) {
        cat("The KEGG pathway data for your organism is not present in the data folder of the SPIA package!")
        cat("\n")
        cat("Trying to download it from http://bioinformaticsprb.med.wayne.edu/SPIA/build012309 ...this may take a few minutes !")
        getSPIAMatrices(organism = organism) # does this line of code really work? hsa = hsa ? -dae
    }
    data(list = datload, envir = .myDataEnv)
################################################################################
################################################################################

    pathwayDatT = .myDataEnv[["path.info"]]
    pathwayDat = list()
    ##############################
    # colNorm takes the sum of all the input columns and divides the input matrix by that sum.
    # the columns are all the upstream genes, rows are downstream genes.
    colNorm = function(x) {
        x.length = dim(x)[1];
        z = matrix( rep(apply(x, 2, sum), x.length ), x.length, x.length, byrow = TRUE)
        z[z == 0] = 1 # prevent divide by zero
        x/z
    }
    pathNames = vector(mode="character", length(pathwayDatT))
    hasReactions = vector(mode="logical", length(pathwayDatT))
    ##############################
    # for every pathway, build a beta matrix:
    for (i in 1:length(pathwayDatT)) {
        # betaSum becomes the beta matrix for the pathway
        pathwayLength = length(pathwayDatT[[i]]$nodes)
        betaSum = matrix(rep(0, pathwayLength**2), nrow=pathwayLength)
        for (j in 1:length(relationships)) {
            ##########
            # this loop builds the beta matrix for each pathway
            betaSum = betaSum + colNorm(pathwayDatT[[i]][[relationships[j]]]) * betaCoefs[relationships[j]]
        }
        pathwayDat[[i]] = betaSum
        pathNames[i]   = pathwayDatT[[i]]$title
        hasReactions[i] = pathwayDatT[[i]]$NumberOfReactions >= 1
    }
    names(pathwayDat) = names(pathwayDatT)
    names(pathNames) = names(pathwayDatT)
    ####################
    # missingDataVect is a vector of length = pathway length. 
	# It contains the index any of the pathways that lack reactions, names or data.
    # This step is trimming out the pathways that don't contain any information for us to use.
    missingDataVect = lapply(pathwayDat, function(d) {
        sum(abs(d))
    }) == 0 | hasReactions | is.na(pathNames)
    pathwayDat = pathwayDat[!missingDataVect]
    pathNames = pathNames[!missingDataVect]

    netAccum = NULL
    set.seed(1) # set random number generator seed, presumably for calls to sample()
	if (plots) {
        pdf("SPIAPerturbationPlots.pdf")
    }
    ##############################
    # preallocate vectors filled with NA.
    netAccum[length(names(pathwayDat))] = NA   
	    # total accumulation - used in hypergeometric with pNDE
    NDE          = netAccum
	    # NDE - the number of differentially expressed genes per pathway
    pNDE         = netAccum
	    # pNDE - the probabilty to observe at least NDE genes on pathway using hypergeometric model
    pathSize     = netAccum
		# pathSize - is the number of genes on the pathway
    pGlobal      = netAccum
	    # pathSize - is the p-value obtained by combining pNDEand pPERT
    pPERT        = netAccum
        # pPERT - is the probability to observe a total accumulation more extreme than netAccum by chance
    sumPertFacts = netAccum
        # sumPertFacts - this is the sum of all the perturbation factors, the numerator from eq(1)
    ##################################################
    # FOR EVERY PATH this.pathName IN THE pathwayDat PATHWAY LIST
    for (i in 1:length(names(pathwayDat))) {
        # I think this.pathName is the name of this pathway
        this.pathName = names(pathwayDat)[i]
        # and this.beta is the associated beta matrix
        this.beta      = pathwayDat[[this.pathName]]
        ##########
        # weird, shouldn't this be 1 - diag(this.beta) ? -dae
        # Yeah, I think this is incorrect based on the publications. It'll return
        # the same result, numerically, but it's not what they published.
        diag(this.beta) = 1 - diag(this.beta)
		##########
        # this.de are the differentially expressed genes (from the
        # user) present in this particular pathway. 
        this.de = de[rownames(this.beta)]
        numThis.de = sum(!is.na(this.de))
        NDE[i] = numThis.de
        pathSize[i] = length(intersect(rownames(this.beta), refGenes))
        refGenesInPathway = rownames(this.beta) %in% refGenes;
        ##############################
        # DET is an R function to calculate the Determinant of the matrix
        if ((numThis.de) > 0 & (abs(det(this.beta)) > 1e-07)) {
            this.de[is.na(this.de)] = 0
            ##############################
            # solve is a call to LAPACK
            pfs = solve(this.beta, -this.de) # why is this negative?
				# x = solve(a, b) for a * x = b which is what we have!
				# so why the negative?
            sumPertFacts[i] = sum(pfs - this.de)
			if (plots) {
                par(mfrow = c(1, 2))
                plot(this.de, pfs - this.de, main = paste("pathway ID=", 
                  names(pathwayDat)[i], sep = ""), xlab = "Log2 FC", 
                  ylab = "Perturbation accumulation (Acc)", cex.main = 0.8, 
                  cex.lab = 1.2)
                abline(h = 0, lwd = 2, col = "darkgrey")
                abline(v = 0, lwd = 2, col = "darkgrey")
                points(this.de[abs(this.de) > 0 & this.de == pfs], pfs[abs(this.de) > 
                  0 & this.de == pfs] - this.de[abs(this.de) > 0 & this.de == pfs], col = "blue", 
                  pch = 19, cex = 1.4)
                points(this.de[abs(this.de) > 0 & this.de != pfs], pfs[abs(this.de) > 
                  0 & this.de != pfs] - this.de[abs(this.de) > 0 & this.de != pfs], col = "red", 
                  pch = 19, cex = 1.4)
                points(this.de[abs(this.de) == 0 & this.de == pfs], pfs[abs(this.de) == 
                  0 & this.de == pfs] - this.de[abs(this.de) == 0 & this.de == pfs], 
                  col = "black", pch = 19, cex = 1.4)
                points(this.de[abs(X) == 0 & this.de != pfs], pfs[abs(this.de) == 
                  0 & this.de != pfs] - this.de[abs(this.de) == 0 & this.de != pfs], 
                  col = "green", pch = 19, cex = 1.4)
            }
            ##############################
            # PHYPER is a call to the hypergeometric function
            pNDE[i] = phyper(q = numThis.de - 1, m = pathSize[i], n = length(refGenes) - 
                pathSize[i], k = length(de), lower.tail = FALSE)
			cat(paste("  ", names(pathwayDat)[i]," phyper (q=numThis.de-1[",numThis.de,"- 1 ], m = pathSize[i][",pathSize[i],"], n = length(refGenes) - pathSize[i][",length(refGenes),"-",pathSize[i],"] k = length(de)[",length(de),"] ) = ", pNDE[i], "\n"))
            ########################################
            # BOOT STRAPPING ON nBoots
            # This section corresponds to the supplementary information for the Tarca et al. Bioinformatics paper, 2009.
            # Specifically part 2, Bootstrap procedure for computing a p-value from pathway perturbations.
            pfs_tmp = vector(mode="numeric", nBoots)
            for (k in 1:nBoots) {
                ####################
                # boot.de is a vector of zeros, length of the this.de vector
                boot.de = vector(mode="numeric", length(this.de))
                names(boot.de) = rownames(this.beta)
                boot.de[refGenesInPathway][sample(1:sum(refGenesInPathway), numThis.de)] = as.vector(sample(de, numThis.de))
                a_pertFact = solve(this.beta, -boot.de) # by equation (7)
                pfs_tmp[k] = sum(a_pertFact - boot.de) # by equation (6)
            }
            med_pfs_tmp = median(pfs_tmp) # by part 2.
            pfs_tmp = pfs_tmp - med_pfs_tmp
			####################
			# FROM THE SUPPLEMENTAL:
			# The median of T_A is computed and subtracted from T_A(k) values, centering their
			# distribution at 0. The resulting corrected values are denoted T_A,c(k). The
			# observed net total accumulation is also corrected for the shift in the null
			# distribution median to give, t_A,c.
            T_Ac = sumPertFacts[i] - med_pfs_tmp
            netAccum[i] = T_Ac
            # these conditionals are by part 2, equation (6)
            if (T_Ac > 0) {
                pPERT[i] = sum(pfs_tmp >= T_Ac) / (length(pfs_tmp) * 2)
            }
            else {
                pPERT[i] = sum(pfs_tmp <= T_Ac) / (length(pfs_tmp) * 2)
            }
            if (pPERT[i] <= 0) {
			   # really? so if the probability of perturbation is less than 0, you're going to set it
			   # equal to 1 / (nBoots * 100) ? And, incidently, is that what they intended with the
			   # order of operations?
                pPERT[i] = 1/nBoots/100
            }
            if (pPERT[i] > 1) {
                pPERT[i] = 1
            }
			if (plots) {
                plot(density(pfs_tmp, bw = sd(pfs_tmp)/4), cex.lab = 1.2, 
                  col = "black", lwd = 2, main = paste("pathway ID=", 
                    names(pathwayDat)[i], "  P PERT=", round(pPERT[i], 
                      5), sep = ""), xlim = c(min(c(netAccum[i] - 0.5, 
                    pfs_tmp)), max(c(netAccum[i] + 0.5, pfs_tmp))), cex.main = 0.8, 
                  xlab = "Total Perturbation Accumulation (TA)")
                abline(v = 0, col = "grey", lwd = 2)
                abline(v = netAccum[i], col = "red", lwd = 3)
            }
            ########################################
            # FROM SPIA LATEX DOCS:
            #  Internal SPIA functions. combfunc() combines two
            #  p-values into a global significance p-value. getP2()
            #  computes the product of two independent p-values that
            #  corresponds to a given global p-value. 
            # THAT SAID:
            #  This just corresponds to part 3 of the supplemental,
            # COMBINING P_NDE AND P_PERT INTO A GLOBAL PATHWAY SIGNIFICANCE MEASURE
            #  Essentially pGlobal = c + c * ln(x) |from c to 1, or c - c*ln(c)
            ########################################
            pGlobal[i] = combfunc.test(pPERT[i], pNDE[i])
        } else {
            ##############################
			# IN ENGLISH:
            #  if ((numThis.de) > 0 & (abs(det(this.beta)) > 1e-07))
            #  {...} else:
            #  the two ways we'll land in this else loop are if the
            #  number of differentially expressed genes is 0 or the
            #  determinant of the beta matrix is less than 1e-07
            #  (tolerance) away from 0. 
            ##############################
            pPERT[i] = pNDE[i] = sumPertFacts[i] = pGlobal[i] = netAccum[i] = NA
        }
        if (verbose) {
            cat(paste("Done pathway ", i, " : ", substr(pathNames[names(pathwayDat)[i]], 
                1, 25), "..","\n", sep = ""))
        }
    }
################################################################################
################################################################################
# CLEANUP AND VARIABLE SAVING
# ... Lots of calls to p.adust() here. That should not take too much work to
#  implement, it's code is easily accessible in R.
########################################
    if (plots) {
        par(mfrow = c(1, 1))
        dev.off()
    }
	cat("\n")
    pGlobalFDR       = p.adjust(pGlobal, "fdr")
    pGlobalBonfer    = p.adjust(pGlobal, "bonferroni")
    Name             = substr(pathNames[names(pathwayDat)], 1, 30)
    ##########
    # Status: condition test to 'if else' function. 
    # if netAccum > 0, then activated
    Status           = ifelse(netAccum > 0, "Activated", "Inhibited")
    result           = data.frame(Name, ID = names(pathwayDat), pathSize, NDE, 
        		      		   netAccum, pNDE, pPERT, pGlobal, pGlobalFDR,
							   pGlobalBonfer, Status)
    result           = na.omit(result[order(result$pGlobal), ])
    rownames(result) = NULL # this looks odd...
    result
}
