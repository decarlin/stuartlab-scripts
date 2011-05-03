#! /usr/bin/env python
"""Takes a set of files.  Assumes each file contains a list of line delimited string.   Returns the intersection of those strings."""

def main():
    import sys
    line_sets = []
    for filehandle in sys.argv[1:]:
        line_sets.append(set([line.strip() for line in open(filehandle)]))

    temp_set = line_sets[0]
    for line_set in line_sets[1:]:
        temp_set = temp_set&line_set

    outlist = list(temp_set)
    for out in outlist:
        print out

if __name__ == '__main__':
    main()

