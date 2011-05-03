#! /usr/bin/env python

def sample_var(sequence_of_values):
    """A function that computes the unbiased sample variance."""
    mean = float(sum(sequence_of_values))/float(len(sequence_of_values))
    SSD = sum([(float(x)-mean)**2 for x in sequence_of_values])
    return SSD/(len(sequence_of_values)-1)

def calculate_fisher_criterion(PopulationZero,PopulationOne,ABS=None):
    mu_zero = float(sum(PopulationZero))/float(len(PopulationZero))
    var_zero = sample_var(PopulationZero)
    mu_one = float(sum(PopulationOne))/float(len(PopulationOne))
    var_one = sample_var(PopulationOne)
    w = (mu_one - mu_zero) / (var_one + var_zero)
    if ABS:
        return abs(w)
    else:
        return w

def main():
    import sys
    import transpose
    TopScoreOut = open(sys.argv[1].rstrip('.tmp')+'_TopScores','w')
    Lines = [Line for Line in open(sys.argv[1])]
    CutOff = float(sys.argv[2])

    Lines_t = transpose.transpose(Lines)
    Scores = []
    for Index,Feature in enumerate(Lines_t[2:]):
        FList = Feature.split()
        length = len(FList)
        MemberClass = [float(val) for val in FList[:length/2] if val != 'NaN']

        VagabondClass = [float(val) for val in FList[length/2:] if val != 'NaN']
        if len(MemberClass) < 3 or len(VagabondClass) < 3:
            continue
        Scores.append((Index+1,calculate_fisher_criterion(MemberClass,VagabondClass,ABS="True")))

    Scores.sort(key=lambda x:x[1])
    TopScoreDict = {}
    for Score in Scores[:int(CutOff*len(Scores))]:
        TopScoreDict[int(Score[0])] = Score[1]
        TopScoreOut.write(str(Score[0])+'\n')
    TopScoreOut.close()
    try:
        OutPut_t = ['F#:\t'+ Lines_t[0]]
    except IndexError:
        print Lines_t
        raise

    OutPut_t.append('C:\t'+Lines_t[1])
    for Index,Feature in enumerate(Lines_t[2:]):
        if TopScoreDict.has_key(Index+1):
            OutPut_t.append(str(Index+1)+'\t'+Feature)

    OutPut = transpose.transpose(OutPut_t)        
    
    if len(sys.argv) == 4:
        Joiner = '\t'+sys.argv[3]
        InsertTarg = OutPut[0]    
        TargSplitList = InsertTarg.split()
        Start = TargSplitList[0]+'\t'+TargSplitList[1]+'\t'
        Inserted = sys.argv[3]+Joiner.join(TargSplitList[2:])
        NewHead = Start+Inserted
        OutPut[0] = NewHead

    for Line in OutPut:
        print Line.rstrip()

if __name__ == '__main__':
    main()
