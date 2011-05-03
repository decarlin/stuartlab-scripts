#! /usr/bin/env python
"""This script takes a single file as an argument.  The file is a category definition.  The script prints the members of the category family with associated ones and an equal number of vagabonds with associated zeros. The vagabond is randomly selected from the available ORFs."""

import random

def FamilyVagabondSample(CategoryDefinition):
    NewFamily = []
    OutSiders = []
    for Def in CategoryDefinition:
        if Def.split()[1].strip() == '1':
            NewFamily.append(Def)
        elif Def.split()[1].strip() == '0':
            OutSiders.append(Def)

    VagaBonds = random.sample(OutSiders,len(NewFamily))
    NewFamily.extend(VagaBonds)
    for line in NewFamily:
        print line.rstrip()
    

    
def main():
    import sys
    lines = [line for line in open(sys.argv[1])]
    FamilyVagabondSample(lines)


if __name__ == '__main__':
    main()

