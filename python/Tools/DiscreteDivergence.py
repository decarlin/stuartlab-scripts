#! /usr/bin/env python

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
        MemberClass = [int(val) for val in FList[:length/2] if val == '1']
        VagabondClass = [int(val) for val in FList[:length/2] if val == '1']
        MCount = sum(MemberClass)
        VCount = sum(VagabondClass)
        Score = (MCount-VCount)**2
        Scores.append((Index+1,Score))

    Scores.sort(key=lambda x:x[1])
    TopScoreDict = {}
    for Score in Scores[:int(CutOff*len(Scores))]:
        TopScoreDict[int(Score[0])] = Score[1]
        TopScoreOut.write(str(Score[0])+'\n')
    TopScoreOut.close()
    OutPut_t = ['F#:\t'+ Lines_t[0]]
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
