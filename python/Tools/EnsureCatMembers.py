#! /usr/bin/env python
"""This script takes two files as arguments.  The first file contains a setmajor list of categories. The second file contains the ORFs that must be among the members of a category for the category to remain included.  The script prints out a list of categories that contain one or more of the ORFs in the second file."""

def main():
    import sys
    ListOfCats = [list for list in open(sys.argv[1])]
    ListOfIncludedORFs = [ORF.strip() for ORF in open(sys.argv[2])]
    ORFSet = set(ListOfIncludedORFs)
    for Cat in ListOfCats:
        SCat = [cat.strip() for cat in Cat.split()]
        Category = SCat[0]
        CatContents = set(SCat[1:])
        intersect = CatContents & ORFSet
        if intersect:
            print Category+'\t'+'\t'.join(intersect)


if __name__ == '__main__':
    main()

