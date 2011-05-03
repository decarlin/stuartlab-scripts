#!/usr/bin/env python
"""layout-cytoscape.py:

Usage:
  layout-cytoscape.py [options] feature

Options:
  -c path   path to cytoscape
  -v path   path to vizmap
  -p path   path to plugins
  -l str    cytoscape layout
  -n        no layout
  -q        run quietly
  
Notes:
  Remember to set up the path to your cytoscape (-c)
  Must be called from LAYOUT/
"""
import os, os.path, sys, getopt, re

verbose = True
#cysPath = "/projects/sysbio/apps/java/Cytoscape/Cytoscape/cytoscape.sh"
cysPath =  "java -jar -Djava.awt.headless=true /projects/sysbio/apps/java/Cytoscape/Cytoscape/cytoscape.jar"
vizPath = "/projects/sysbio/apps/java/Cytoscape/Cytoscape/vizmap/vizmap.props"
pluginPath = "/projects/sysbio/apps/java/Cytoscape/Cytoscape/plugins"
layoutSpec = 'layout.default="force-directed" defaultVisualStyle="Local-Red-Blue-On-White"'
searchDirs = "FILTER_"
netExtension = "sif"

def usage(code=0):
    print __doc__
    if code != None: sys.exit(code)

def log(msg):
    if (verbose):
        sys.stderr.write(msg)

def main(args):
    ## Parse arguments
    try:
        opts, args = getopt.getopt(args, "c:v:p:l:qn")
    except getopt.GetoptError, err:
        print str(err)
        usage(2)
    
    if len(args) != 1:
        print "incorrect number of arguments"
        usage(1)
    
    feature = args[0]
    
    nolayout = False
    global verbose, cysPath, vizPath, pluginPath, layoutSpec
    for o, a in opts:
        if o == "-c":
            cysPath = a
        elif o == "-v":
            vizPath = a
        elif o == "-p":
            pluginPath = a
        elif o == "-l":
            layoutSpec = a
        elif o == "-q":
            verbose = False
        elif o == "-n":
            nolayout = True
    
    ## Check structure
    assert os.path.exists("node_types.tab")
    assert os.path.exists("scores.tab")
    
    ## Create node attribute files
    if not os.path.exists("TYPE.NA"):
        f = open("node_types.tab")
        labelf = open("LABEL.NA", "w")
        typef = open("TYPE.NA", "w")
        labelf.write("LABEL (class=java.lang.String)\n")
        typef.write("TYPE (class=java.lang.String)\n")
        f.readline()
        for line in f:
            line = line.rstrip("\n\r")
            if line.isspace():
                continue
            pline = re.split("\t", line)
            if pline[1] == "protein":
                labelf.write("%s = %s\n" % (pline[0], pline[0]))
            else:
                labelf.write("%s = %s\n" % (pline[0], ""))
            typef.write("%s = %s\n" % (pline[0], pline[1]))
        f.close()
	labelf.close()
	typef.close()
    if not os.path.exists("%s_SCORE.NA" % (feature)):
        f = open("scores.tab", "r")
        scoref = open("%s_SCORE.NA" % (feature), "w")
        scoref.write("SCORE (class=java.lang.Double)\n")
        line = f.readline()
        line = line.rstrip("\n\r")
        pline = re.split("\t", line)
        index = 0
        while True:
            if pline[index] == feature:
                break
            index += 1
            if index >= len(pline):
                log("ERROR: feature not found in scores.tab\n")
                sys.exit(1)
        for line in f:
            line = line.rstrip("\n\r")
            if line.isspace():
                continue
            pline = re.split("\t", line)
            try:
                pline[index] = float(pline[index])
            except ValueError:
                pline[index] = 0
            if pline[0].endswith("(DRUG)"):
                scoref.write("%s = 24\n" % (pline[0]))
            elif pline[0].endswith("(GRAYDRUG)"):
	        scoref.write("%s = -24\n" % (pline[0]))
            else:
                scoref.write("%s = %s\n" % (pline[0], pline[index]))
        f.close()
        scoref.close()
    if nolayout:
        sys.exit(0)

    ## Identify nets with feature
    filterDirs = list()
    for i in os.listdir("."):
        if i.startswith(searchDirs):
            filterDirs.append(i)
    sifFiles = list()
    for i in filterDirs:
        for j in os.listdir(i+"/"+feature):
            if j.endswith(netExtension):
                sifFiles.append(i+"/"+feature+"/"+j)
    
    ## Launch cytoscape
    cmd = "%s -N %s -n LABEL.NA TYPE.NA %s_SCORE.NA -V %s -p %s -P %s" % (cysPath, " ".join(sifFiles), feature, vizPath, pluginPath, layoutSpec)
    log(cmd+"\n")
    os.system(cmd)

   
if __name__ == "__main__":
    main(sys.argv[1:])
