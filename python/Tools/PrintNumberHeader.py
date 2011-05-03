#! /usr/bin/env python


def main():
    import sys
    headlist = [line for line in open(sys.argv[1])]
    OutString = 'F#:\t'
    for Int in range(len(headlist[0].split())):
        OutString = OutString + str(Int) + '\t'

    print OutString.rstrip()


if __name__ == '__main__':
    main()

