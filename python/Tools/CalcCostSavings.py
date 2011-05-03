#! /usr/bin/env python

def SavingsCalculator(TrueValues,ClassificationValues):
    TruePositives  = 0
    TrueNegatives  = 0
    FalsePositives = 0
    FalseNegatives = 0
    NullPositives  = 0
    for TV,CV in zip(TrueValues,ClassificationValues):
        TVStart = TV[0]
        CVStart = TV[0]
        if CVStart != '-':
            NullPositives+=1
        if CVStart == '-' and TVStart == '-':
            TrueNegatives+=1
        if CVStart != '-' and TVStart != '-':
            TruePositives+=1
        if CVStart != '-' and TVStart == '-':
            FalsePositives+=1
        if CVStart == '-' and TVStart != '-':
            FalseNegatives+=1
    
    CostMethod = FalsePositives + FalseNegatives
    CostNull   = NullPositives 
    CostSavings = CostNull - CostMethod
    return FalsePositives,FalseNegatives,TruePositives,TrueNegatives,CostSavings


def main():
    import sys
    TrueLines = [line.strip() for line in open(sys.argv[1])]
    ClassLines = [line.strip() for line in open(sys.argv[2])]
    print SavingsCalculator(TrueLines,ClassLines)
    


if __name__ == '__main__':
    main()

