#! /usr/bin/env python
import random

def WriteNFiles(SupportVectors,N=5):
    N = int(N)
    random.shuffle(SupportVectors)
    nth = len(SupportVectors)/N
    segments = []
    for coeff in range(N):
        segments.append(SupportVectors[coeff*nth:(coeff+1)*nth])
    if nth*N != len(SupportVectors):
        segments[-1].append(SupportVectors[-1])
    count = 0
    for name in ["Number_"+str(i+1).zfill(3) for i in range(N)]:
        infh = open('test_'+name,'w')
        outfh = open('train_'+name,'w')
        temp_in = segments.pop(0)
        for line in temp_in:
            infh.write(line)
        infh.close()
        for seg in segments:
            for line in seg:
                outfh.write(line)
        outfh.close()
        segments.append(temp_in)

def main():
    import sys
    svs = [line for line in open(sys.argv[1])]
    if len(sys.argv) == 3:
        WriteNFiles(svs,sys.argv[2])
    else:
        WriteNFiles(svs)

if __name__ == '__main__':
    main()

