## Calculate module
## Written By: Sam Ng
## Last Updated: 3/15/11
import math, sys
import mData

def log(msg, die = False):
    sys.stderr.write(msg)
    if die:
        sys.exit(1)

def mean (inList):
    """Calculates mean"""
    
    cList = mData.floatList(inList)
    if len(cList) == 0:
        mean = "NA"
    else:
        mean = sum(cList)/len(cList)
    return (mean)

def mean_std (inList, sample = True):
    """Calculates mean and std"""
    
    cList = mData.floatList(inList)
    if len(cList) == 0:
        mean = "NA"
        std = "NA"
    else:
        mean = sum(cList)/float(len(cList))
        std = 0.0
        for i in cList:
            std += (i-mean)**2
        if len(cList) > 1:
            if sample:
                std = math.sqrt(std/(len(cList)-1))
            else:
                std = math.sqrt(std/len(cList))
        else:
            std = 0.0
    return(mean, std)

def median (inList):
    """Calculates median"""
    
    cList = mData.floatList(inList)
    cList.sort()
    if len(cList) == 0:
        median = "NA"
    else:
        if len(cList)%2 == 1:
            median = cList[len(cList)/2]
        else:
            median = (cList[len(cList)/2]+cList[(len(cList)/2)-1])/2.0
    return(median)

def pcorrelation(list1, list2):
    """Calculates pearson correlation"""
        
    if len(list1) != len(list2):
        log("ERROR: sizes of list are not equal\n", die = True)
    mean1 = mean(list1)
    mean2 = mean(list2)
    cov = 0.0
    stdev1 = 0.0
    stdev2 = 0.0
    for i in range(len(list1)):
        try:
            fval1 = float(list1[i])
            fval2 = float(list2[i])
            cov += (fval1-mean1)*(fval2-mean2)
            stdev1 += (fval1-mean1)**2
            stdev2 += (fval2-mean2)**2
        except:
            continue
    stdev1 = math.sqrt(stdev1)
    stdev2 = math.sqrt(stdev2)
    if stdev1 == 0 or stdev2 == 0:
        value = "NA"
    else:
        value = cov/(stdev1*stdev2)
    return(value)

def correlationMatrix(outf, inf):
    """Takes a tab file and cross-correlates the columns"""
    
    outData = dict()
    inData = mData.rCRSData(inf)
    inCols = inData.keys()
    inRows = inData[inCols[0]].keys()
    for i in inCols:
        outData[i] = dict()
        outData[i][i] = 1.0
    for i in range(len(inCols)-1):
        list1 = []
        for k in inRows:
            list1.append(inData[inCols[i]][k])
        for j in range(i+1, len(inCols)):
            list2 = []
            for k in inRows:
                list2.append(inData[inCols[j]][k])
            value = pcorrelation(list1, list2)
            outData[inCols[i]][inCols[j]] = value
            outData[inCols[j]][inCols[i]] = value
    mData.wCRSData(outf, outData)       

def ttest(group0, group1, inData):
    scoreMap = dict()
    for i in inData[inData.keys()[0]].keys():
        values0 = []
        values1 = []
        for j in inData.keys():
            if inData[j][i] == "NA":
                continue
            if j in group0:
                values0.append(inData[j][i])
            elif j in group1:
                values1.append(inData[j][i])
        if (len(values0) < 2) | (len(values1) < 2):
            scoreMap[i] = "NA"
        else:
            (mean0, std0) = mean_std(values0)
            (mean1, std1) = mean_std(values1)
            if (std0 == 0) & (std1 == 0):
                scoreMap[i] = "NA"
            else:
                scoreMap[i] = (mean0-mean1)/math.sqrt((std0**2)/len(values0)+(std1**2)/len(values1))
    return(scoreMap)

def zIPL(inData):
    scoreMap = dict()
    for i in inData[inData.keys()[0]].keys():
        values = []
        for j in inData.keys():
            if inData[j][i] == "NA":
                continue
            else:
                values.append(inData[j][i])
        if len(values) < 2:
            scoreMap[i] = 0
        else:
            (mean, std) = mean_std(values)
            if std == 0:
                scoreMap[i] = 0
            else:
                scoreMap[i] = (mean)/(std)
    return(scoreMap)

def sign(value):
    """Returns the sign"""
    if value == 0:
        return(0)
    elif value > 0:
        return(1)
    elif value < 0:
        return(-1)
