#Pathway module
#Written By: Sam Ng
#Last Updated: 5/17/11
import re, sys
import mData
from copy import deepcopy

def rPathway(inf, reverse = False, retProteins = False, delim = "\t"):
    """read UCSC pathway tab"""
    inNodes = dict()                            #Dictionary with (A : type)
    inInteractions = dict()                     #Dictionary with (A : (B : interaction))
    proteins = set()                            #Set of features in pathway
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if len(pline) == 2:
            inNodes[pline[1]] = pline[0]
            if pline[0] == "protein":
                proteins.update([pline[1]])
        elif len(pline) == 3:
            if reverse:
                if pline[1] not in inInteractions:
                    inInteractions[pline[1]] = dict()
                if pline[0] not in inInteractions[pline[1]]:
                    inInteractions[pline[1]][pline[0]] = pline[2]
                else:
                    inInteractions[pline[1]][pline[0]] += ";"+pline[2]
            else:
                if pline[0] not in inInteractions:
                    inInteractions[pline[0]] = dict()
                if pline[1] not in inInteractions[pline[0]]:
                    inInteractions[pline[0]][pline[1]] = pline[2]
                else:
                    inInteractions[pline[0]][pline[1]] += ";"+pline[2]
        else:
            print >> sys.stderr, "ERROR: line length not 2 or 3: \"%s\"" % (line)
            sys.exit(1)
    f.close()
    if retProteins:
        return(inNodes, inInteractions, proteins)
    else:
        return(inNodes, inInteractions)

def rSIF(inf, typef = None, reverse = False):
    """read .sif"""
    inNodes = dict()                            #Dictionary with (A : type)
    inInteractions = dict()                     #Dictionary with (A : (B : interaction))
    nodeMap = dict()
    if typef != None:
        nodeMap = mData.r2Col(typef, delim = " = ", header = True)
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split("\s*\t\s*", line)
        if pline[0] not in inNodes:
            if pline[0] in nodeMap:
                inNodes[pline[0]] = nodeMap[pline[0]]
            else:
                inNodes[pline[0]] = "concept"
        if pline[2] not in inNodes:
            if pline[2] in nodeMap:
                inNodes[pline[2]] = nodeMap[pline[2]]
            else:
                inNodes[pline[2]] = "concept"
        if reverse:
            if pline[2] not in inInteractions:
                inInteractions[pline[2]] = dict()
            if pline[0] not in inInteractions[pline[2]]: 
                inInteractions[pline[2]][pline[0]] = pline[1]
            else:
                inInteractions[pline[2]][pline[0]] += ";"+pline[1]
        else:
            if pline[0] not in inInteractions:
                inInteractions[pline[0]] = dict()
            if pline[2] not in inInteractions[pline[0]]:
                inInteractions[pline[0]][pline[2]] = pline[1]
            else:
                inInteractions[pline[0]][pline[2]] += ";"+pline[1]
    f.close()
    return(inNodes, inInteractions)

def wSIF(outf, outInteractions, useNodes = None):
    """write .sif"""
    f = open(outf, "w")
    if useNodes == None:
        for i in outInteractions.keys():
            for j in outInteractions[i].keys():
                for k in re.split(";", outInteractions[i][j]):
                    f.write("%s\t%s\t%s\n" % (i, k, j))
    else:
        for i in useNodes:
            if i not in outInteractions:
                continue
            for j in outInteractions[i].keys():
                if j not in useNodes:
                    continue
                for k in re.split(";", outInteractions[i][j]):
                    f.write("%s\t%s\t%s\n" % (i, k, j))
    f.close()

def wPathway(outf, outNodes, outInteractions, useNodes = None):
    """write UCSC pathway.tab"""
    f = open(outf, "w")
    if useNodes == None:
        useNodes = outNodes.keys()
    for i in useNodes:
        if i not in outNodes:
            continue
        f.write("%s\t%s\n" % (outNodes[i], i))
    for i in useNodes:
        if i not in outInteractions:
            continue
        for j in outInteractions[i].keys():
            if j not in useNodes:
                continue
            for k in re.split(";", outInteractions[i][j]):
                f.write("%s\t%s\t%s\n" % (i, j, k))
    f.close()

def wAdj(outf, outNodes, outInteractions, useNodes = None, symmetric = False, signed = True):
    """write adjacency matrix from interactions (cols = SOURCE, rows = TARGET)"""
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

def getComponentMap(allNodes, revInteractions):
    """create the dictionary componentMap from interaction map"""
    componentMap = dict()
    for i in allNodes.keys():
        if allNodes[i] != "complex":
            continue
        if i not in revInteractions:
            continue
        componentMap[i] = []
        for j in revInteractions[i]:
            if revInteractions[i][j] == "component>":
                componentMap[i].append(j)
    return(componentMap)

def filterTerminalComplexes(allNodes, forInteractions, revInteractions):
    """remove terminal complexes"""
    lastCount = -1
    while lastCount != len(allNodes.keys()):
        lastCount = len(allNodes.keys())
        for i in allNodes.keys():
            if allNodes[i] == "complex":
                numLinks = 0
                if i in forInteractions:
                    numLinks += len(forInteractions[i].keys())
                if i in revInteractions:
                    numLinks += len(revInteractions[i].keys())
                if numLinks < 2:
                    removeNode(i, allNodes, forInteractions, revInteractions)
    return(allNodes, forInteractions)

def filterUnsupportedComplexes(allNodes, forInteractions, revInteractions, componentMap, percent = 50):
    """remove complexes with less than percent support"""
    for i in allNodes.keys():
        ## skip non-complexes
        if allNodes[i] != "complex":
            continue
        ## count members
        count = 0
        for j in componentMap[i]:
            if j in allNodes:
                count += 1
        ## remove complexes with 0 components
        if len(componentMap[i]) == 0:
            (allNodes, forInteractions, revInteractions) = removeNode(i, allNodes, forInteractions, revInteractions)
        ## skip supported complexes
        if count/float(len(componentMap[i])) <= percent:
            continue
        ## remove unsuppported complexes
        (allNodes, forInteractions, revInteractions) = removeNode(i, allNodes, forInteractions, revInteractions)
    return(allNodes, forInteractions)

def revInteractions(inInteractions):
    """reverse interaction mapping"""
    outInteractions = dict()
    for i in inInteractions.keys():
        for j in inInteractions[i].keys():
            if j not in outInteractions:
                outInteractions[j] = dict()
            outInteractions[j][i] = inInteractions[i][j]
    return(outInteractions)

def constructInteractions(nodeList, inNodes, inInteractions):
    """select concepts from list and construct Nodes and Interactions"""
    outNodes = dict()
    outInteractions = dict()
    for i in nodeList:
        outNodes[i] = inNodes[i]
        if i in inInteractions:
            for j in inInteractions[i].keys():
                if j in nodeList:
                    if i not in outInteractions:
                        outInteractions[i] = dict()
                    outInteractions[i][j] = inInteractions[i][j]
    return(outNodes, outInteractions)

def addInteractions(inf, inNodes, inInteractions, delim = "\t"):
    """read in interactions and append to current pathway mappings"""
    outNodes = deepcopy(inNodes)
    outInteractions = deepcopy(inInteractions)
    f = open(inf, "r")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if len(pline) != 3:
            print >> sys.stderr, "ERROR: line length not 3: \"%s\"" % (line)
            sys.exit(1)
        if pline[0] not in outInteractions:
            outInteractions[pline[0]] = dict()
        if pline[1] not in outInteractions[pline[0]]:
            outInteractions[pline[0]][pline[1]] = pline[2]
        if pline[2] == "component>":
            if pline[0] not in outNodes:
                outNodes[pline[0]] = "protein"
            if pline[1] not in outNodes:
                outNodes[pline[1]] = "complex"
        elif (pline[2] == "-a>") | (pline[2] == "-a|"):
            if pline[0] not in outNodes:
                outNodes[pline[0]] = "protein"
            if pline[1] not in outNodes:
                outNodes[pline[1]] = "protein"
        elif (pline[2] == "-t>") | (pline[2] == "-t|"):
            if pline[0] not in outNodes:
                outNodes[pline[0]] = "protein"
            if pline[1] not in outNodes:
                outNodes[pline[1]] = "protein"
        elif (pline[2] == "-ap>") | (pline[2] == "-ap|"):
            if pline[0] not in outNodes:
                outNodes[pline[0]] = "protein"
            if pline[1] not in outNodes:
                outNodes[pline[1]] = "abstract"
        else:
            print >> sys.stderr, "ERROR: unknown interaction type \"%s\"" % (pline[2])
            sys.exit(1)
    f.close()
    return(outNodes, outInteractions)

def removeNode(i, allNodes, forInteractions, revInteractions):
    del allNodes[i]
    if i in forInteractions:
        for j in forInteractions[i].keys():
            del forInteractions[i][j]
            if len(forInteractions[i].keys()) == 0:
                del forInteractions[i]
            del revInteractions[j][i]
            if len(revInteractions[j].keys()) == 0:
                del revInteractions[j]
    if i in revInteractions:
        for j in revInteractions[i].keys():
            del forInteractions[j][i]
            if len(forInteractions[j].keys()) == 0:
                del forInteractions[j]
            del revInteractions[i][j]
            if len(revInteractions[i].keys()) == 0:
                del revInteractions[i]
    return(allNodes, forInteractions, revInteractions)

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

def getDownstream(node, distance, forInteractions):
    """returns downstream neighbors of distance"""
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
    """returns upstream and downstream neighbors of distance"""
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
