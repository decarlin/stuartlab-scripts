## Data module
## Written By: Sam Ng
## Last Updated: 7/12/11
import re, sys, urllib2, os, random
from copy import deepcopy
import mCalculate

def log(msg, die = False):
    """logger function"""
    sys.stderr.write(msg)
    if die:
        sys.exit(1)

def openAnyFile(inf):
    """performs an open() on a file or url"""
    if inf.startswith("http"):
        stream = urllib2.urlopen(inf)
    else:
        stream = open(inf, 'r')
    return stream

def retColumns(inf, delim = "\t"):
    """returns the columns of a .tsv"""
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank header\n", die = True)
    line = line.rstrip("\r\n")
    return(re.split(delim, line)[1:])

def retRows(inf, delim = "\t"):
    """returns the rows of a .tsv"""
    rows = []
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank header\n", die = True)
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        rows.append(re.split(delim, line)[0])
    return(rows)
    
def rCRSData(inf, appendData = dict(), delim = "\t", retFeatures = False, debug = False):
    """reads .tsv into a [col][row] dictionary"""
    inData = deepcopy(appendData)
    colFeatures = []
    rowFeatures = []
    ## read header
    f = openAnyFile(inf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 1\n", die = True)
    line = line.rstrip("\r\n")
    pline = re.split(delim, line)
    if debug:
        log("%s\nLENGTH: %s\n" % (line, len(pline)))
    colFeatures = pline[1:]
    for i in colFeatures:
        if i not in inData:
            inData[i] = dict()
    ## read data
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        rowFeatures.append(pline[0])
        if debug:
            log("%s\nLENGTH: %s\n" % (line, len(pline)))
        if len(pline) != (1+len(colFeatures)):
            log("ERROR: length of line does not match the rest of the file\n", die = True)
        for i in range(len(colFeatures)):
            if pline[i+1] == "":
                inData[colFeatures[i]][pline[0]] = "NA"
            else:            
                inData[colFeatures[i]][pline[0]] = pline[i+1]
    f.close()
    if retFeatures:
        return(inData, colFeatures, rowFeatures)
    else:
        return(inData)

def wCRSData(outf, outData, delim = "\t", useCols = None, useRows = None):
    """write [col][row] dictionary to .tsv"""
    ## get colFeatures and rowFeatures
    if useCols is None:
        colFeatures = outData.keys()
    else:
        colFeatures = useCols
    if useRows is None:
        rowFeatures = outData[colFeatures[0]].keys()
    else:
        rowFeatures = useRows
    ## write header
    f = open(outf, "w")
    f.write("id")
    for i in colFeatures:
        f.write("\t%s" % (i))
    f.write("\n")
    for i in rowFeatures:
        f.write("%s" % (i))
        for j in colFeatures:
            if j in outData:
                if i in outData[j]:
                    f.write("\t%s" % (outData[j][i]))
                else:
                    f.write("\tNA") 
            else:
                f.write("\tNA")
        f.write("\n")
    f.close()

def rwCRSData(outf, inf, delim = "\t", useCols = None, useRows = None, null = "NA", numeric = False, enumerateRows = False):
    """read and write .tsv for lower memory usage and efficiency"""
    f = openAnyFile(inf)
    o = open(outf, "w")
    ## read header
    line = f.readline()
    if line.isspace():
        log("ERROR: no header found\n", die = True)
    line = line.rstrip("\r\n")
    dataCols = re.split(delim, line)[1:]
    ## write header
    if useCols is None:
        useCols = set(dataCols)
    outCols = list(set(useCols)&set(dataCols))+list(set(useCols)-set(dataCols))
    outCols.sort()
    o.write("id")
    for i in outCols:
        o.write("\t%s" % (i))
    o.write("\n")
    ## read and write rest of the file
    if enumerateRows:
        rowID = 0
        e = open(outf+".fmap", "w")
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split(delim, line)
        if useRows is not None:
            if pline[0] not in useRows:
                continue
        if enumerateRows:
            rowID += 1
            rowItem = "rid_%s" % (rowID)
            e.write("%s\t%s\n" % (pline[0], rowItem))
        else:
            rowItem = pline[0]
        ## read row
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
        ## write row
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
    if enumerateRows:
        e.close()
    f.close()
    o.close()

def r2Col(inf, appendData = dict(), delim = "\t", header = False, null = ""):
    """read 2 column data"""
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
    """read 2 column categories mapping"""
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
    """read sets file"""
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
    """read 1 column list"""
    inList = list()
    f = openAnyFile(inf)
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        inList.append(line)
    f.close()
    return(inList)

def lineCount(inf):
    """returns line count"""
    f = openAnyFile(inf)
    for i, l in enumerate(f):
        pass
    f.close()
    return(i+1)

def rMeta(clinf, delim = "\t", null = True):
    """read .meta format clinical information"""
    metaLabels = dict()
    f = openAnyFile(clinf)
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 1\n", die = True)
    line = line.rstrip("\r\n")
    pline = re.split(delim, line)
    samples = pline[1:]
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 2\n", die = True)
    line = line.rstrip("\r\n")
    pline = re.split(delim, line)
    for i in range(len(samples)):
        if not null:
            if pline[i+1] == "NULL":
                continue
        metaLabels[samples[i]] = pline[i+1]
    return(metaLabels)

def wMeta(inf, col, method = "discrete", mparams = "-;-1;0,+;1", name = None, samples = None, directory = "."):
    """write .meta format clinical information"""
    cData = rCRSData(inf)[col]
    if name == None:
        name = re.sub(" ", "", col)
    if samples == None:
        samples = cData.keys()
    if directory.endswith("/"):
        directory = directory.rstrip("/")
    f = open("%s/%s.metadata" % (directory, name), "w")
    f.write("labels\t"+"\t".join(samples)+"\n")
    vals = []
    if method == "discrete":
        labelList = []
        for i in re.split(",", mparams):
            labelList.append(re.split(";", i))
        for i in samples:
            for label, j in enumerate(labelList):
                if i not in cData:
                    vals.append("NULL")
                    break
                elif cData[i] in j:
                    vals.append(str(label))
                    break
                elif label+1 == len(labelList):
                    vals.append("NULL")
    elif method == "quartile":
        medVal = mCalculate.median(cData[i].values())
        for j in samples:
            try:
                if float(cData[i][j]) > medVal:
                    f.write("\t1")
                else:
                    f.write("\t0")
            except ValueError:
                f.write("\tNULL")
    f.write("knownVal\t"+"\t".join(vals)+"\n")
    f.close()

def getSplits(splitf, limit = None):
    """read .folds format file"""
    splitMap = dict()
    f = openAnyFile(splitf)
    ## Header
    line = f.readline()
    if line.isspace():
        log("ERROR: encountered a blank on line 1\n", die = True)
    line = line.rstrip("\r\n")
    colFeatures = re.split("\t", line)[1:]
    ## Data
    r = 0
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\r\n")
        pline = re.split("\t", line)
        if len(pline) != (1+len(colFeatures)):
            log("ERROR: length of line does not match the rest of the file\n", die = True)
        r += 1
        splitMap[r] = dict()
        for i in range(len(colFeatures)):
            if pline[i+1] not in splitMap[r]:
                splitMap[r][pline[i+1]] = set()
            splitMap[r][pline[i+1]].update([colFeatures[i]])
        if limit is not None:
            if r >= limit:
                break
    f.close()
    return(splitMap)

def createSplits(samples0, samples1, seed = None, nrepeats = 1, mfolds = 5):
    """create splitMap from samples"""
    if seed != None:
        random.seed(seed)
    if (len(samples0) < mfolds) | (len(samples1) < mfolds):
        log("ERROR: Not enough samples for mfold\n", die = True)
    splitMap = dict()
    for r in range(1, nrepeats+1):
        select0 = deepcopy(samples0)
        select1 = deepcopy(samples1)
        sampleMap = dict()
        splitMap[r] = dict()
        for m in range(1, mfolds+1):
            splitMap[r][m] = set()
        while len(select0)+len(select1) > 0:
            for m in range(1, mfolds+1):
                if len(select0) > 0:
                    sampleMap[select0.pop(random.randint(0,len(select0)-1))] = m
                else:
                    sampleMap[select1.pop(random.randint(0,len(select1)-1))] = m
                if len(select0)+len(select1) == 0:
                    break
        for i in sampleMap.keys():
            splitMap[r][sampleMap[i]].update([i])
    return(splitMap)

def rMAF(inf, delim = "\t", retSamples = False):
    """read .maf format file"""
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
    samples = []
    for line in f:
        if line.isspace():
            continue
        line = line.rstrip("\t\r\n")
        pline = re.split(delim, line)
        if pline[hugoCol] not in mutData:
            mutData[pline[hugoCol]] = list()
        mutData[pline[hugoCol]].append(pline[tumorCol])
        if pline[tumorCol] not in samples:
            samples.append(pline[tumorCol])
    f.close()
    if retSamples:
        return(mutData, samples)
    else:
        return(mutData)

def rVCF(inf, delim = "\t"):
    """read .vcf files from directory"""
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

def wMutData(outf, mutData, samples, features):
    """write mutation data into a paradigm rawFile"""
    f = open(outf, "w")
    f.write("id\t%s\n" % ("\t".join(features)))
    for i in samples:
        f.write("%s" % (i))
        for j in features:
            if j not in mutData:
                f.write("\t%s" % ("NA"))
            else:
                if i in mutData[j]:
                    f.write("\t%s" % ("1"))
                else:
                    f.write("\t%s" % ("0"))
        f.write("\n")
    f.close()

def floatList(inList):
    """returns only numeric elements of a list"""
    outList = []
    for i in inList:
        try:
            fval = float(i)
            if fval != fval:
                raise ValueError
            outList.append(fval)
        except ValueError:
            continue
    return(outList)

def applyData(inData, fh):
    outData = dict()
    for i in inData.keys():
        outData[i] = dict()
        for j in inData[i].keys():
            outData[i][j] = fh(inData[i])
    return(outData)