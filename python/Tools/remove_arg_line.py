#! /usr/bin/env python
"""A command line utility that expects a single file as an argument, and returns a list of all lines in the file that do not match the passed in first parameter more than second parameter times."""
def main():
    import sys
    ofileh = open('excess'+sys.argv[1]+'.tab','w')
    lines = [line for line in open(sys.argv[-1])]
    BadArgs = []
    GoodArgs = []
    for line in lines:
        if line.count(sys.argv[1]) <= int(sys.argv[2]):
            GoodArgs.append(line.rstrip('\n'))
        else:
            BadArgs.append(line.rstrip('\n'))

    #print len(BadArgs)
    #print len(GoodArgs)
    for line in GoodArgs:
        #pass
        print line

    for bline in BadArgs:
        ofileh.write(bline+'\n')
    ofileh.close()


if __name__ == '__main__':
    main()

