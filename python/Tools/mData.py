## Data module
## Written By: Sam Ng
## Last Updated: 4/1/11
import re, sys, urllib2
from copy import deepcopy
import mCalculate

def log(msg, die = False):
    sys.stderr.write(msg)
    if die:
        sys.exit(1)

def openAnyFile(inf):
    if inf.startswith("http"):
        stream = urllib2.urlopen(inf)
    else:
        stream = open(inf, 'r')
    return stream

def retColumns(inf, delim = "\t"):
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank header\n", die = True)
    line = line.rstrip("\r\n")
    return(re.split(delim, line)[1:])

def retRows(inf, delim = "\t"):
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank header\n", die = True)
    line = line.rstrip("\r\n")
    
    return(re.split(delim, line)[1:])
    
def rCRSData(inf, appendData = dict(), delim = "\t", retFeatures = False, rmFilter = set(), debug = False):
    """Read simple tab-delimited data [column][row] mappings"""
    
    inData = deepcopy(appendData)                 #Dictionary with (column : (row : data))
    colFeatures = list()
    rowFeatures = list()
    ## Read header
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 1\n", die = True)
    line = line.rstrip("\r\n")
    pline = re.split(delim, line)
    if debug:
        log(line+"\n")
        log("LENGTH: %s\n" % (len(pline)))
    colFeatures = pline[1:]
    for i in colFeatures:
        if i not in inData:
            inData[i] = dict()
    ## Read data
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        rowFeatures.append(pline[0])
        if debug:
            log(line+"\n")
            log("LENGTH: %s\n" % (len(pline))) 
        if len(pline) != (1+len(colFeatures)):
            log("ERROR: length of line does not match the rest of the file\n", die = True)
        for i in range(len(colFeatures)):
            if pline[i+1] in rmFilter:
                inData[colFeatures[i]][pline[0]] = "NA"
            elif pline[i+1].isspace():
                inData[colFeatures[i]][pline[0]] = "NA"
            else:            
                inData[colFeatures[i]][pline[0]] = pline[i+1]
    f.close()
    if retFeatures:
        return(inData, colFeatures, rowFeatures)
    else:
        return(inData)

def wCRSData(outf, outData, delim = "\t", useCols = None, useRows = None, printNA = True):
    """Write simple column by row data"""
    
    ## Extract colFeatures and rowFeatures
    dataFeatures = None
    if useCols is None:
        colFeatures = outData.keys()
    else:
        colFeatures = useCols
    if useRows is None:
        rowFeatures = outData[colFeatures[0]].keys()
    else:
        rowFeatures = useRows
    
    ## Write header
    f = open(outf, "w")
    f.write("id")
    for i in colFeatures:
        if i in outData:
            f.write("\t%s" % (i))
            if dataFeatures is None:
                dataFeatures = set(outData[i].keys())
        else:
            if printNA:
                f.write("\t%s" % (i))
            else:
                log("Removing column: %s\n" % (i))
    f.write("\n")
    for i in rowFeatures:
        if (i in dataFeatures) | (printNA):
            f.write("%s" % (i))
        else:
            log("Removing row: %s\n" % (i))
            continue
        for j in colFeatures:
            if j in outData:
                if i in outData[j]:
                    f.write("\t%s" % (outData[j][i]))
                else:
                    f.write("\tNA") 
            else:
                if printNA:
                    f.write("\tNA")
        f.write("\n")
    f.close()

def rwCRSData(outf, inf, delim = "\t", useCols = None, useRows = None, replace = "[@]", null = "NA", numeric = False):
    """Read and Write data for lower memory usage and efficiency"""
    
    seenRows = set()
    f = openAnyFile(inf)
    o = open(outf, "w")
    line = f.readline()
    if line.isspace():
        log("ERROR: no header found\n", die = True)
    line = line.rstrip("\r\n")
    dataCols = re.split(delim, line)[1:]
    if useCols is None:
        useCols = set(dataCols)
    outCols = list(set(useCols)&set(dataCols))+list(set(useCols)-set(dataCols))
    outCols.sort()
    o.write("id")
    for i in outCols:
        o.write("\t%s" % (i))
    o.write("\n")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        rowItem = re.sub(replace, "", pline[0])
        if useRows is not None:
            if rowItem not in useRows:
                continue
        if rowItem in seenRows:
            continue
        seenRows.update([rowItem])
        lData = dict()
        for i in range(len(dataCols)):
            if numeric:
                try:
                    fval = float(pline[i+1])
                    lData[dataCols[i]] = "%.10f" % (fval)
                except ValueError:
                    lData[dataCols[i]] = null
            else:
                lData[dataCols[i]] = pline[i+1]

        o.write("%s" % (rowItem))
        for i in outCols:
            if i in lData:
                if lData[i] == "":
                    o.write("\t%s" % (null))
                else:
                    o.write("\t%s" % (lData[i]))
            else:
                o.write("\t%s" % (null))
        o.write("\n")
    f.close()
    o.close()

def rMAF(inf, delim = "\t"):
    mutData = dict()
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 1\n", die = True)
    line = line.rstrip("\r\n")
    pline = re.split(delim, line)
    hugoCol = -1
    tumorCol = -1
    for i, j in enumerate(pline):
        if j == "Hugo_Symbol":
            hugoCol = i
        elif j == "Tumor_Sample_Barcode":
            tumorCol = i
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split(delim, line)
        if pline[hugoCol] not in mutData:
            mutData[pline[hugoCol]] = list()
        mutData[pline[hugoCol]].append(pline[tumorCol])
    f.close()
    return(mutData)

def rVCF(inf, delim = "\t"):
    mutSet = set()
    f = openAnyFile(inf)
    for line in f:
        if line.isspace():
            continue
        if line.startswith("#"):
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split(delim, line)
        gene = re.split("[=/]", pline[7])[1]
        if gene not in mutSet:
            mutSet.update([gene])
    f.close()
    return(mutSet)

def r3Col(inf, features = False):
    """Read 3 column data"""
    
    inData = dict()
    fSet = set()
    sSet = set()
    f = openAnyFile(inf)
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split("\s*\t\s*", line)
        if len(pline) != 3:
            log("ERROR: Length of data line is not 3\n", die = True)
        if pline[0] not in inData:
            inData[pline[0]] = dict()
        inData[pline[0]][pline[1]] = pline[2]
        fSet.update([pline[0]])
        sSet.update([pline[1]])
    f.close()
    if features:
        return(inData, fSet, sSet)
    else:
        return(inData)

def r2Col(inf, appendData = dict(), delim = "\t", header = False, null = ""):
    """Read 2 column data"""
    
    inData = deepcopy(appendData)
    f = openAnyFile(inf)
    if header:
        line = f.readline()
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if len(pline[1]) == 0:
            pline[1] = null
        if len(pline) != 2:
            log("ERROR: Length of data line is not 2\n", die = True)
        inData[pline[0]] = pline[1]
    f.close()
    return(inData)

def rCategory(inf, delim = "\t", header = False):
    """Read category file"""
    
    inCat = dict()
    f = openAnyFile(inf)
    if header:
        line = f.readline()
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if len(pline) != 2:
            log("ERROR: Length of line is not 2\n", die = True)
        if pline[1] not in inCat:
            inCat[pline[1]] = []
        inCat[pline[1]].append(pline[0])
    f.close()
    return(inCat)

def rSet(inf, header = True, delim = "\t", enumerate = False):
    """Read sets file"""
    
    inSets = dict()                 #Dictionary with (name : set)
    f = openAnyFile(inf)
    if header:
        f.readline()
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split(delim, line)
        if enumerate:
            value = 1
            while "_".join([pline[0]]+[value]) in inSets:
                value += 1
            inSets["_".join([pline[0]]+[value])] = set(pline[1:])
        else:
            inSets[pline[0]] = set(pline[1:])
    f.close()
    return(inSets)

def rList(inf):
    """Read 1 column list"""
    
    inList = list()
    f = openAnyFile(inf)
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        inList.append(line)
    f.close()
    return(inList)

def floatList(inList):
    """Takes a list and returns it with only numeric elements"""
    
    outList = []
    for i in inList:
        try:
            outList.append(float(i))
        except ValueError:
            continue
    return(outList)
        
def rPDataFeatures(inf):
    """Read PARADIGM Data for features"""
    
    features = set()
    samples = set() 
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("Features not found on line 1\n", die = True)
    line = line.rstrip("\t\r\n")
    features = set(re.split("\s*\t\s*", line)[1:])
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split("\s*\t\s*", line)
        samples.update([pline[0]])
    f.close()
    return (features, samples)

def rPARADIGM(inf, delim = "\t"):
    """Read PARADIGM Output"""
    
    inLikelihood = dict()
    inScore = dict()
    f = openAnyFile(inf)
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        if line.startswith(">"):
            pline = re.split("[= ]", line)
            sample = pline[1]
            inLikelihood[sample] = float(pline[3])
            inScore[sample] = dict()
        else:
            pline = re.split(delim, line)
            feature = pline[0]    
            inScore[sample][feature] = float(pline[1])
    f.close()
    return(inLikelihood, inScore)

def lineCount(inf):
    """line count"""
    
    f = open(inf, "r")
    for i, l in enumerate(f):
        pass
    f.close()
    return(i+1)

def hSamples(datasets, directory = "homogenized", replace = "[ \[\]_()/*,:+@']", null = "NULL", numeric = True):
    samples = None
    for i in datasets:
        dsamples = set(retColumns(i))
        if samples == None:
            samples = dsamples
        else:
            samples = samples & dsamples
    if not os.path.exists(directory):
        os.system("mkdir %s" % (directory))
    for i in datasets:
        rwCRSData(directory+"/"+re.split("/", i)[-1], i, useCols = samples, replace = replace, null = null, numeric = numeric)

def wMeta(clinf, samples, directory = "."):
    cData = rCRSData(clinf)
    for i in cData.keys():
        f = open(directory+"/"+re.split("/", i)[-1]+".metadata", "w")
        f.write("labels\t"+"\t".join(samples)+"\n")
        f.write("knownVal")
        if len(set(cData[i].values())-set(["", "NULL", "null", "NA"])) == 2:
            for j in samples:
                if j in cData[i]:
                    if cData[i][j] in ["", "NULL", "null", "NA"]:
                        f.write("\tNULL")
                    elif cData[i][j] in ["+", "1"]:
                        f.write("\t1")
                    elif cData[i][j] in ["-", "0", "-1"]:
                        f.write("\t0")
                    else:
                        f.write("\t%s" % (cData[i][j]))
        else:
            medVal = mCalculate.median(cData[i].values())
            for j in samples:
                try:
                    if float(cData[i][j]) > medVal:
                        f.write("\t1")
                    else:
                        f.write("\t0")
                except ValueError:
                    f.write("\tNULL")
        f.write("\n")
        f.close()
