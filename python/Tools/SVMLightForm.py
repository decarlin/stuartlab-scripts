#! /usr/bin/env python

def BuildFeatureDict(PositionedFeatureString):
    PositionedFeatureList = [FeatNum.strip() for FeatNum in PositionedFeatureString.split()[2:]]
    FeatureNumberDict = {}
    for Index,Number in enumerate(PositionedFeatureList):
        FeatureNumberDict[Index+1]=Number
    return FeatureNumberDict

def SVMLightFormLine(FlatFormLine,FeatureNumberDict):
    FlatForValList = [Val.strip() for Val in FlatFormLine.split()]
    Class = FlatForValList[1]
    if Class == '0':
        OutSVMLine = '-1 '
    elif Class == '1':
        OutSVMLine = '1 '
    for Index,Val in enumerate(FlatForValList[2:]):
        ValStrip = Val.strip()
        if ValStrip != 'NaN':
            OutSVMLine = OutSVMLine + FeatureNumberDict[Index+1]+':'+ValStrip+' '
    return OutSVMLine.rstrip()

def main():
    import sys
    InLines = [line for line in open(sys.argv[1])]
    FeatureDict = BuildFeatureDict(InLines[0])
    OutLines = []
    for IL in InLines[1:]:
        print SVMLightFormLine(IL,FeatureDict)


if __name__ == '__main__':
    main()

