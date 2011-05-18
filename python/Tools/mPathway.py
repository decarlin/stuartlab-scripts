#Pathway module
#Written By: Sam Ng
#Last Updated: 4/28/11
import re, sys
from copy import deepcopy

def rPathway(inf, returnProteins = False, reverse = False):
    """Read UCSC Pathway Format"""
    
    inNodes = dict()                            #Dictionary with (A : type)
    inInteractions = dict()                     #Dictionary with (A : (B : interaction))
    proteins = set()                            #Set of features in pathway
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split("\s*\t\s*", line)
        if len(pline) == 2:
            inNodes[pline[1]] = pline[0]
            if pline[0] == "protein":
                proteins.update([pline[1]])
        elif len(pline) == 3:
            if reverse:
                if pline[1] not in inInteractions:
                    inInteractions[pline[1]] = dict()
                inInteractions[pline[1]][pline[0]] = pline[2]
            else:
                if pline[0] not in inInteractions:
                    inInteractions[pline[0]] = dict()
                inInteractions[pline[0]][pline[1]] = pline[2]
        else:
            print >> sys.stderr, "ERROR: line length not 2 or 3: \"%s\"" % (line)
            sys.exit(1)
    f.close()
    if returnProteins:
        return(inNodes, inInteractions, proteins)
    else:
        return(inNodes, inInteractions)

def rSIF(inf, typef = "concept", reverse = False):
    """Read SIF"""
    
    inNodes = dict()                            #Dictionary with (A : type)
    inInteractions = dict()                     #Dictionary with (A : (B : interaction))
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split("\s*\t\s*", line)
        if pline[0] not in inNodes:
            inNodes[pline[0]] = type
        if pline[2] not in inNodes:
            inNodes[pline[2]] = type
        if reverse:
            if pline[2] not in inInteractions:
                inInteractions[pline[2]] = dict()
            inInteractions[pline[2]][pline[0]] = pline[1]
        else:
            if pline[0] not in inInteractions:
                inInteractions[pline[0]] = dict()
            inInteractions[pline[0]][pline[2]] = pline[1]
    f.close()
    return(inNodes, inInteractions)

def wSIF(outf, outInteractions, ignoreNodes = []):
    """Output SIF"""
    
    f = open(outf, "w")
    for i in outInteractions.keys():
        if i in ignoreNodes:
            continue
        for j in outInteractions[i].keys():
            if j in ignoreNodes:
                continue
            f.write("%s\t%s\t%s\n" % (i, outInteractions[i][j], j))
    f.close()

def wPathway(outf, outNodes, outInteractions, ignoreNodes = []):
    """Output UCSC Pathway"""
    
    f = open(outf, "w")
    for i in outNodes.keys():
        if i in ignoreNodes:
            continue
        f.write("%s\t%s\n" % (outNodes[i], i))
    for i in outInteractions.keys():
        if i in ignoreNodes:
            continue
        for j in outInteractions[i].keys():
            if j in ignoreNodes:
                continue
            f.write("%s\t%s\t%s\n" % (i, j, outInteractions[i][j]))
    f.close()

def wAdj(outf, outNodes, outInteractions, useNodes = None, symmetric = False, signed = True):
    """Output adjacency matrix from interactions (cols = SOURCE, rows = TARGET)"""
    
    if useNodes is None:
        useNodes = outNodes.keys()
    else:
        for i in useNodes:
            if i not in outNodes.keys():
                print >> sys.stderr, "WARNING: %s in include not found in pathway" % (i)    
    f = open(outf, "w")
    f.write("\t".join(["id"]+useNodes)+"\n")
    val = None
    for i in useNodes:
        f.write("%s" % (i))
        for j in useNodes:
            val = 0
            if i in outInteractions:
                if j in outInteractions[i]:
                    if (outInteractions[i][j].endswith("|") & signed):
                        val = -1
                    else:
                        val = 1
            if (symmetric & (j in outInteractions)):
                if i in outInteractions[j]:
                    if (outInteractions[j][i].endswith("|") & signed):
                        val = -1
                    else:
                        val = 1
            f.write("\t%s" % (val))
        f.write("\n")
    f.close()

def filterComplexes(inNodes, inInteractions):
    del inNodes[blah]
    del inInteractions[blah][blah]
    return(inNodes, inInteractions)

def addPPI(inf, inNodes, inInteractions, delim = "\t"):
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if len(pline) != 3:
            print >> sys.stderr, "ERROR: line length not 3: \"%s\"" % (line)
            sys.exit(1)
        if pline[0] not in inInteractions:
            inInteractions[pline[0]] = dict()
        inInteractions[pline[0]][pline[1]] = pline[2]
        if pline[2] == "component>":
            if pline[0] not in inNodes:
                inNodes[pline[0]] = "protein"
            if pline[1] not in inNodes:
                inNodes[pline[1]] = "complex"
    f.close()
    return(inNodes, inInteractions)

def largestConnected(allNodes, forInteractions, revInteractions):
    ## Identify largest net
    largestNet = []
    seenNodes = set()
    for i in allNodes.keys():
        if i in seenNodes:
            continue
        borderNodes = [i]
        currentNet = [i]
        while len(borderNodes) > 0:
            if borderNodes[0] in revInteractions:
                for j in revInteractions[borderNodes[0]].keys():
                    if j not in seenNodes:
                        seenNodes.update([j])
                        borderNodes.append(j)
                        currentNet.append(j)
            if borderNodes[0] in forInteractions:
                for j in forInteractions[borderNodes[0]].keys():
                    if j not in seenNodes:
                        seenNodes.update([j])
                        borderNodes.append(j)
                        currentNet.append(j)
            borderNodes.pop(0)
        if ("__DISCONNECTED__" not in currentNet) & (len(currentNet) > len(largestNet)):
            largestNet = deepcopy(currentNet)
    ## Build largest net
    lNodes = dict()
    lInteractions = dict()
    for i in (largestNet):
        lNodes[i] = allNodes[i]
        if i in forInteractions:
            for j in forInteractions[i].keys():
                if i not in lInteractions:
                    lInteractions[i] = dict()
                lInteractions[i][j] = forInteractions[i][j]
    return(lNodes, lInteractions)

def sortConnected(allNodes, forInteractions, revInteractions, method = "size", addData = None):
    index = 1
    mapNets = dict()
    sortedNets = []
    seenNodes = set()
    for i in allNodes.keys():
        if i in seenNodes:
            continue
        borderNodes = [i]
        currentNet = [i]
        while len(borderNodes) > 0:
            if borderNodes[0] in revInteractions:
                for j in revInteractions[borderNodes[0]].keys():
                    if j not in seenNodes:
                        seenNodes.update([j])
                        borderNodes.append(j)
                        currentNet.append(j)
            if borderNodes[0] in forInteractions:
                for j in forInteractions[borderNodes[0]].keys():
                    if j not in seenNodes:
                        seenNodes.update([j])
                        borderNodes.append(j)
                        currentNet.append(j)
            borderNodes.pop(0)
        if ("__DISCONNECTED__" not in currentNet):
            mapNets[index] = deepcopy(currentNet)
            index += 1
    indexList = mapNets.keys()
    netScore = dict()
    for i in indexList:
        if method == "size":
            netScore[i] = len(mapNets[i])
        elif method == "average":
            values = []
            for j in mapNets[i]:
                if j in addData:
                    if addData[j] != "NA":
                        values.append(abs(addData[j]))
            if len(values) > 0:
                netScore[i] = sum(values)/len(values)
            else:
                netScore[i] = 0.0
        elif method == "overlap":
            netScore[i] = len(set(mapNets[i]) & addData)
    indexList.sort(lambda x, y: cmp(netScore[y], netScore[x]))
    for i in indexList:
        sortedNets.append(mapNets[i])
    return(sortedNets)

def constructInteractions(netNodes, allNodes, forInteractions):
    cNodes = dict()
    cInteractions = dict()
    for i in (netNodes):
        cNodes[i] = allNodes[i]
        if i in forInteractions:
            for j in forInteractions[i].keys():
                if i not in cInteractions:
                    cInteractions[i] = dict()
                cInteractions[i][j] = forInteractions[i][j]
    return(cNodes, cInteractions)

def reverseInteractions(forInteractions):
    """Reverse interaction dictionary"""
    
    revInteractions = dict()
    for i in forInteractions.keys():
        for j in forInteractions[i].keys():
            if j not in revInteractions:
                revInteractions[j] = dict()
            revInteractions[j][i] = forInteractions[i][j]
    return(revInteractions)

def getDownstream(node, distance, forInteractions):
    seenNodes = set([node])
    borderNodes = [node]
    frontierNodes = []
    for dist in range(distance):
        while len(borderNodes) > 0:
            currNode = borderNodes.pop()
            if currNode in forInteractions:
                for i in forInteractions[currNode].keys():
                    if i not in seenNodes:
                        seenNodes.update([i])
                        frontierNodes.append(i)
        borderNodes = deepcopy(frontierNodes)
        frontierNodes = list()
    return(seenNodes)

def getNeighbors(node, distance, forInteractions, revInteractions):
    seenNodes = set([node])
    borderNodes = [node]
    frontierNodes = []
    for dist in range(distance):
        while len(borderNodes) > 0:
            currNode = borderNodes.pop()
            if currNode in forInteractions:
                for i in forInteractions[currNode].keys():
                    if i not in seenNodes:
                        seenNodes.update([i])
                        frontierNodes.append(i)
            if currNode in revInteractions:
                for i in revInteractions[currNode].keys():
                    if i not in seenNodes:
                        seenNodes.update([i])
                        frontierNodes.append(i)
        borderNodes = deepcopy(frontierNodes)
        frontierNodes = list()
    return(seenNodes)
