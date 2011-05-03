#! /usr/bin/env python
"""
Created by Josh Wilcox (2008-02-04)
syntax: makemap.py [OPTIONS] FILE

This script take a single two column whitespace delimited file, and produces a mapping of all the unique elements in one column to all of the elements in the other column.  keys are strings matching the unique ids in the specified "key" column (the left column by default) and values are a list of all strings in the "value" column (the right column by default) that are paired with (i.e. on the same \n delimited line as) a give "key".

OPTIONS are:
-c | --column:   This option, if specified, identies which column will be used as keys in the mapping "-R" indicates the "Right" column and "-L" indicated the "Left" column.  By default the script assumes "-L".

"""

class InvalidArgError(Exception): pass
    #def __init__(self,BadKey):
        #from makemap import __doc__
        #self.doc = __doc__
        #self.bk = BadKey
        
def buildcolumntabcolumndict(FileLines,Key='L'):
    if Key == 'L':
        KeyColumn = 0
        ValueColumn = 1
    elif Key == 'R':
        KeyColumn = 1
        ValueColumn = 0
    else:
        #import makemap
        #print makemap.__doc__
        raise InvalidArgError(Key)
    CTCdict = {}
    
    for line in FileLines:
        sline = line.split()
        KEY = sline[KeyColumn].strip()
        VALUE = sline[ValueColumn].strip()
        if CTCdict.has_key(KEY):
            CTCdict[KEY].append(VALUE)
        else:
            CTCdict[KEY] = [VALUE]
    return CTCdict

def main():
    import sys,getopt
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option("-f", "--file", dest="filename")
    parser.add_option("-c", "--column")
    (options,args) = parser.parse_args()
    if not options.column:
        options.column = 'L'
    if not options.filename:
        options.filename = args[0]
    fl = [line for line in open(options.filename)]
    mapping = buildcolumntabcolumndict(fl,options.column)
    for k,v in mapping.iteritems():
        v = '\t'.join(v)
        print k,'\t',v
    
if __name__ == '__main__':
    main()

