#! /usr/bin/env python

def transpose(ListOfLines):
    ListOfTransposed = []
    for line in ListOfLines:
        sline = line.split('\t')
        for index, atom in enumerate(sline):
            try:
                ListOfTransposed[index] = ListOfTransposed[index] + '\t' + atom.strip()
            except IndexError, instance:
                if instance.message == 'list index out of range':
                    ListOfTransposed.append(atom.strip())
    return ListOfTransposed
def main():
    import sys
    transposed_lines = transpose([ line for line in open(sys.argv[1])])
    for tline in transposed_lines:
        print tline

if __name__ == '__main__':
    main()

