#!/usr/bin/env python
"""filter-subnets.py: identifies subnets in a score-matrix (feature x phenotype)

Usage:
  filter-subnets.py [options] scoref [scoref ...]

Options:
  -p  str       phenotype[;phenotype;...] <- phenotypes
  -s  str       mean;std[,mean;std,...] <- forced stats
  -f  str       lower;upper <- filter parameters 
  -d  str       output directory     
  -l  str       output largest connected net with at least featureReq number of genes in list
  -n            output node attributes for cytoscape
  -q            run quietly
"""
## Written By: Sam Ng
## Last Updated: 6/2/11
import os, os.path, sys, getopt, re
sys.path.append("/projects/sysbio/lab_apps/python/Tools")
import mData, mPathway, mCalculate
from copy import deepcopy

verbose = True
includeType = "OR"
filterBounds = [0,0]
topDisconnected = 100

outputAttributes = False
outputPARADIGM = False
includePARADIGM = ""
featureReq = 1

if os.path.exists("/projects/sysbio/map/Data/Pathways/Paradigm/SuperPathway/data.tab"):
    globalPathway = "/projects/sysbio/map/Data/Pathways/Paradigm/SuperPathway/data.tab"
else:
    globalPathway = "/home/kuromajutsu/Desktop/Dropbox/My_Research/bin/subnets/SuperPathway/data.tab"
if os.path.exists("/projects/sysbio/map/Data/Drugs/Human/DrugBank/data.tab"):
    drugBank = "/projects/sysbio/map/Data/Drugs/Human/DrugBank/data.tab"

def usage(code = 0):
    print __doc__
    if code != None: sys.exit(code)

def log(msg, die = False):
    if (verbose):
        sys.stderr.write(msg)
    if (die):
        sys.exit(1)
    
def syscmd(cmd):
    log("running:\n\t"+cmd+"\n")
    exitstatus = os.system(cmd)
    if exitstatus != 0:
        print "Failed with exit status %i" % exitstatus
        sys.exit(10)
    log("... done\n")

def addLink(a, b, pNodes, pInteractions, gNodes, gInteractions):
    if a not in pNodes:
        pNodes[a] = gNodes[a]
    if b not in pNodes:
        pNodes[b] = gNodes[b]
    if a not in pInteractions:
        pInteractions[a] = dict()
    pInteractions[a][b] = gInteractions[a][b]
    return(pNodes, pInteractions)

def filterNet(files, phenotypes = [], statLine = None, outDir = None, outDir_defined = False):
    global filterBounds
    filterString = "%s_%s" % (filterBounds[0], filterBounds[1])
    
    ## Read global pathway
    (gNodes, gInteractions) = mPathway.rPathway(globalPathway)
    
    ## Read drugs
    #drugData = mData.rSet(drugBank)
    
    ## Write LABEL.NA, TYPE.NA
    if outputAttributes:
        typef = open("TYPE.NA", "w")
        labelf = open("LABEL.NA", "w")
        typef.write("TYPE (class=java.lang.String)\n")
        labelf.write("LABEL (class=java.lang.String)\n")
        for i in gNodes.keys():
            typef.write("%s = %s\n" % (i, gNodes[i]))
            if gNodes[i] == "protein":
                labelf.write("%s = %s\n" % (i, i))
            else:
                labelf.write("%s = %s\n" % (i, ""))
        #drugs here
        typef.close()
        labelf.close()
    
    ## Read scores
    uData = dict()
    sData = dict()
    for i in range(len(files)):
        uData[i] = mData.rCRSData(files[i])
        sData[i] = dict()
        for j in uData[i].keys():
            sData[i][j] = dict()
            for k in uData[i][j].keys():
                try:
                    sData[i][j][k] = abs(float(uData[i][j][k]))
                except ValueError:
                    sData[i][j][k] = "NA"
    
    ## Iterate phenotypes
    for p in sData[0].keys():
        if len(phenotypes) > 0:
            if p not in phenotypes:
                continue
        pNodes = dict()
        pInteractions = dict()
        
        ## Write SCORE.NA
        if outputAttributes:
            scoref = open(p+"_SCORE.NA", "w")
            scoref.write("SCORE (class=java.lang.Float)\n")
            for i in gNodes.keys():
                if i in uData[0][p]:
                    if uData[0][p][i] == "NA":
                        scoref.write("%s = %s\n" % (i, "0"))
                    else:
                        scoref.write("%s = %s\n" % (i, uData[0][p][i]))
                else:
                    scoref.write("%s = %s\n" % (i, "0"))
            scoref.close()
            if 1 in uData:
                scoref = open(p+"_INFLUENCE.NA", "w")
                scoref.write("INFLUENCE (class=java.lang.Float)\n")
                for i in gNodes.keys():
                    if i in uData[1][p]:
                        scoref.write("%s = %s\n" % (i, uData[1][p][i]))
                    else:
                        scoref.write("%s = %s\n" % (i, "0"))
                scoref.close()
        
        ## Compute thresholds
        pStats = []
        if statLine == None:
            for i in range(len(sData.keys())):
                pStats.append(mCalculate.mean_std(sData[i][p].values()))
        else:
            for i in re.split(",",statLine):
                (v1, v2) = re.split(";",i)
                pStats.append((float(v1), float(v2)))
        log("%s\t%s;%s" % (p, pStats[0][0], pStats[0][1]))
        for i in range(1, len(pStats)):
            log(",%s;%s" % (pStats[i][0], pStats[i][1]))
        log("\n")
        
        ## Iterate links
        for a in gInteractions.keys():
            if a not in sData[0][p]:
                continue
            elif sData[0][p][a] == "NA":
                continue
            for b in gInteractions[a].keys():
                if b not in sData[0][p]:
                    continue
                elif sData[0][p][b] == "NA":
                    continue
                aScore = []
                bScore = []
                linkScore = []
                for i in range(len(sData.keys())):
                    linkScore.append([sData[i][p][a], sData[i][p][b]])
                for i in range(len(sData.keys())):
                    if linkScore[i][0] > pStats[i][0]+filterBounds[1]*pStats[i][1]:
                        aScore.append(2)
                    elif linkScore[i][0] > pStats[i][0]+filterBounds[0]*pStats[i][1]:
                        aScore.append(1)
                    else:
                        aScore.append(0)
                    if linkScore[i][1] > pStats[i][0]+filterBounds[1]*pStats[i][1]:
                        bScore.append(2)
                    elif linkScore[i][1] > pStats[i][0]+filterBounds[0]*pStats[i][1]:
                        bScore.append(1)
                    else:
                        bScore.append(0)
                
                ## Selection rule
                if includeType == "OR":
                    if max(aScore)+max(bScore) >= 3:
                        (pNodes, pInteractions) = addLink(a, b, pNodes, pInteractions, gNodes, gInteractions)
                elif includeType == "AND":
                    votes = 0
                    for i in range(len(sData.keys())):
                        if aScore[i]+bScore[i] >= 3:
                            votes += 0
                    if votes == len(sData.keys()):
                        (pNodes, pInteractions) = addLink(a, b, pNodes, pInteractions, gNodes, gInteractions)
                elif includeType == "MAIN":
                    if aScore[0]+bScore[0] >= 3:
                        (pNodes, pInteractions) = addLink(a, b, pNodes, pInteractions, gNodes, gInteractions)
        
        ## Connect top scoring
        sortedTop = sData[0][p].keys()
        sortedTop.sort(lambda x, y: cmp(sData[0][p][y],sData[0][p][x]))
        while (sData[0][p][sortedTop[0]] == "NA"):
            sortedTop.pop(0)
            if len(sortedTop) == 0:
                break
        for i in range(topDisconnected):
            if i > len(sortedTop)-1:
                break
            if sortedTop[i] not in gNodes:
                continue
            if sortedTop[i] not in pNodes:
                pNodes[sortedTop[i]] = gNodes[sortedTop[i]]
                pInteractions[sortedTop[i]] = dict()
                pInteractions[sortedTop[i]]["__DISCONNECTED__"] = "-disconnected-"
        
        ## Output
        if not outDir_defined:
            outDir = p+"/"
        if not os.path.exists(outDir):
            os.system("mkdir %s" % (outDir))

        ## Output for pathway-predictor
        if outputPARADIGM:
            dataSet = set(mData.rList(includePARADIGM))
            netNodes = mPathway.sortConnected(pNodes, pInteractions, mPathway.reverseInteractions(pInteractions))
            #netNodes = mPathway.sortConnected(pNodes, pInteractions, mPathway.reverseInteractions(pInteractions), method = "overlap", addData = dataSet)
            #netNodes = mPathway.sortConnected(pNodes, pInteractions, mPathway.reverseInteractions(pInteractions), method = "average", addData = sData[0][p])
            largestNodes = []
            for i in netNodes:
                if len((dataSet) & set(i)) > featureReq:
                    log("found %s features with data in net\n" % (len((dataSet) & set(i))))
                    largestNodes = i
                    break
            if len(largestNodes) == 0:
                log("ERROR: no nets contained enough data\n...trying again\n")
                if filterBounds[0]+0.1 <= filterBounds[1]:
                    filterBounds[1] -= 0.1
                else:
                    filterBounds[0] -= 0.1
                    filterBounds[1] -= 0.1
                filterNet(files, phenotypes = phenotypes, statLine = statLine, outDir = outDir, outDir_defined = outDir_defined)
                sys.exit(0)
            (lNodes, lInteractions) = mPathway.constructInteractions(largestNodes, pNodes, pInteractions)
            mPathway.wPathway(outDir+p+"_"+filterString+"_largest.tab", lNodes, lInteractions)
            if outputAttributes:
                mPathway.wSIF(outDir+p+"_"+filterString+"_largest.sif", lInteractions)
        
        ## Output nodrug pathway
        else:
            mPathway.wSIF(outDir+p+"_"+filterString+"_nodrug.sif", pInteractions)
        
        ## Attach drugs
        
        ## Output drug pathway
        #if outputSIF:
        #    mPathway.wSIF(outDir+p+"_"+filterString+"_drug.sif", pInteractions)
 

if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], "p:s:f:d:l:nq")
    except getopt.GetoptError, err:
        print str(err)
        usage(2)
    
    if len(args) < 1:
        print "incorrect number of arguments"
        usage(1)
    
    phenotypes = []
    statLine = None
    outDir = None
    outDir_defined = False
    for o, a in opts:
        if o == "-p":
            phenotypes = re.split(";", a)
        elif o == "-s":
            statLine = a
            if os.path.exists(statLine):
                f = open(statLine, "r")
                statLine = re.split("\t", f.readline().rstrip("\r\n"))[1]
                f.close()
        elif o == "-f":
            (v1, v2) = re.split(";", a)
            filterBounds = [float(v1), float(v2)]
            filterBounds.sort()
        elif o == "-d":
            outDir = a
            if (not outDir.endswith("/")):
                outDir += "/"
            outDir_defined = True
        elif o == "-l":
            outputPARADIGM = True
            includePARADIGM = a
        elif o == "-n":
            outputAttributes = True
        elif o == "-q":
            verbose = False
    filterNet(args, phenotypes = phenotypes, statLine = statLine, outDir = outDir, outDir_defined = outDir_defined)
