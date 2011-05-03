#! /usr/bin/env python
import random

def WriteFiveFiles(SupportVectors):
    random.shuffle(SupportVectors)
    fifth = len(SupportVectors)/5
    segments = []
    for coeff in range(5):
        segments.append(SupportVectors[coeff*fifth:(coeff+1)*fifth])
    if fifth*5 != len(SupportVectors):
        segments[-1].append(SupportVectors[-1])
    count = 0
    for name in ['one','two','three','four','five']:
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
    WriteFiveFiles(svs)

if __name__ == '__main__':
    main()

