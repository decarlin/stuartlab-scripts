#!/usr/bin/env python2.6

import urllib, re, string

def get_ncbi_codon_table(name):
    """

    Arguments:
        -name: either the English or the systematic name for the NCBI codon table, or
        the id number
    """     

    # hardcode it -- should be stable since it's the ncbi
    # and not too hard to change here

    url = "ftp://ftp.ncbi.nih.gov/entrez/misc/data/gc.prt"

    # map codon string to the amino acid letter
    table = {}

    fh = None
    try:
        fh = urllib.urlopen(url)
    except IOError:
        raise Exception("Can't connect to NCBI!")
        return 1
   

    # state data 
    found_table = False

    # this is what we need to generate the table
    # each is a length 64 string and the mappings are vertically
    # aligned
    ncbieaa = None
    sncbieaa = None
    base1 = None
    base2 = None
    base3 = None

    for line in fh.readlines():

        # either the name or ID 
        if re.search("\s+name\s+\""+name+"\"\s*,", line):
            found_table = True
            continue
        if re.search("\s+id\s+"+name+"\s*,", line):
            found_table = True
            continue

        if not found_table:
            continue

        m = re.search("\s+ncbieaa\s+\"(\S+)\"",line)
        if m:
            ncbieaa = m.group(1)
            continue

        m = re.search("\s+sncbieaa\s+\"(\S+)\"",line)
        if m:
            sncbieaa = m.group(1)
            continue
        
        m = re.search("\s+--\s+Base1\s+(\S+)",line)
        if m:
            base1 = m.group(1)
            continue

        m = re.search("\s+--\s+Base2\s+(\S+)",line)
        if m:
            base2 = m.group(1)
            continue

        m = re.search("\s+--\s+Base3\s+(\S+)",line)
        if m:
            base3 = m.group(1)
            break
 
    if not found_table:
        raise Exception("Couldn't find table for name %s" % name) 
    if not base3:
        raise Exception("Found table for name %s but couldn't parse it" % name) 

    for i in range(0, len(ncbieaa)): 
        table[base1[i]+base2[i]+base3[i]] = ncbieaa[i] if sncbieaa[i] == "-" else sncbieaa[i] 
   
    return table 

def parse_codon_pref_table(url):
    """
        Parse a text codon text table in the ncbi 4x4 format and return
        a dictionary of codon usage counts, fractions per AA, and the AA
        each codon maps to

        Arguments:
            - an open filehandle to a standard codon usage table

        Returns:
            - a dictionary of codon usage dictionaries:
            each codon usage dictionary contains a 'aa', 'count', and 'fraction' key
    
    """

    fh = None
    try:
        fh = urllib.urlopen(url)
    except IOError:
        raise Exception("Can't connect to freq table resource!")

    # report simple parsing errors 
    found_table = False

    # RNA -> DNA
    RNA_2_DNA = string.maketrans("AUGC", "ATGC")
 
    # 4 codon usage blocks per line - separated by space 
    line_pattern = re.compile("(\w.*?\))\s*(\w.*?\))\s*(\w.*?\))\s*(\w.*?\))")
    # each block looks like this: UUU F 0.59 26.3 ( 22246)
    # and is defined by the following regex
    codon_pattern = re.compile("(\w{3})\s*(\d+\.\d+)\s*\(\s*(\d+)\)") 
    codon_usage = {}
    for line in fh.readlines(): 

        if line.isspace():
            continue
        # each part looks like 'CODON AA FRAC FREQ NUMBER

        m = line_pattern.match(line)
        if not m:
            continue

        found_table = True
        # have to get past some HTML junk before we get to the actual 
        # table here:
        components = m.group(1), m.group(2), m.group(3), m.group(4)
        for component in components:
        
            m = codon_pattern.match(component)
            if not m:
                raise Exception("Failed to parse codon table!")

            codon, frequency, number = m.group(1), m.group(2), m.group(3)

            # frequency is per 1000 -- convert it to a prob
            codon_usage[codon.translate(RNA_2_DNA)] = float(frequency) / 1000

    if not found_table:
        raise Exception("Failed to parse codon table!")

    return codon_usage



