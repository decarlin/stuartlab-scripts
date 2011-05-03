#! /usr/bin/env python
"""This script takes a single file as an argument.  The file is a category definition.  The script prints the members of the category family with associated ones and an equal number of vagabonds with associated zeros. The vagabond is randomly selected from the available ORFs."""

import random

def FamilyVagabondSample(CategoryDefinition):
    Family = []
    OutSiders = []
    for Def in CategoryDefinition:
        if Def.split()[1].strip() == '1':
            Family.append(Def.split()[0].strip())
        elif Def.split()[1].strip() == '0':
            OutSiders.append(Def.split()[0].strip())

    print "len(Family): %s"%len(Family)
    print "len(OutSiders): %s"%len(OutSiders)

    
def main():
    import sys
    lines = [line for line in open(sys.argv[1])]
    FamilyVagabondSample(lines)


if __name__ == '__main__':
    main()

