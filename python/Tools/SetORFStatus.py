#! /usr/bin/env python
"""This script: Takes two files as arguments.  The first file is a list of categories, in set major tab-delimited format.  The second file is a list of the ORFs in the data set to be run.  Based on the name of the directory, this script picks a category from the first file.  It then sends a string for each ORF defined in the second file to stdout followed by a tab delimited 1 if the ORF is in the category, or zero if it is not."""

def MakeCatDict(CatMajorList,CatName):
    CategoryDict = {}
    for line in CatMajorList:
        sline = line.split()
        if sline[0].strip() == CatName:
            for ORF in sline[1:]:
                CategoryDict[ORF.strip()] = 1
            break   
    return CategoryDict

def CategoryAssigner(DictOfCategory,ListOfPotentials):
    for Potential in ListOfPotentials:
        if DictOfCategory.has_key(Potential):
            print Potential+'\t1'
        else:
            print Potential+'\t0'

def main():
    import sys,os
    CatMajorList = [line for line in open(sys.argv[1])]
    CatName = os.path.basename(os.getcwd())
    print "CatName: %s"%CatName
    PotentiaList = [line.strip() for line in open(sys.argv[2])]
    CategoryDict = MakeCatDict(CatMajorList,CatName)
    CategoryAssigner(CategoryDict,PotentiaList)
    


if __name__ == '__main__':
    main()

