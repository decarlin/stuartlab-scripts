#!/usr/bin/env python
"""layout-cytoscape.py: Generate cytoscape sessions from .sif and
   .NA files

Usage:
  layout-cytoscape.py [options] feature

Options:
  -c path   path to cytoscape
  -v path   path to vizmap
  -p path   path to plugins
  -l str    cytoscape layout
  -q        run quietly
  
Notes:
  Remember to set up your path (-c, -v, -p)
"""
## Written By: Sam Ng
## Last Updated: 5/17/11
import os, os.path, sys, getopt, re

verbose = True
cysPath = "/home/kuromajutsu/LocalLibs/Cytoscape_v2.8.0/cytoscape.sh"
vizPath = "/home/kuromajutsu/Desktop/Dropbox/My_Research/bin/subnets/vizmap.props"
pluginPath = "/home/kuromajutsu/LocalLibs/Cytoscape_v2.8.0/plugins"
layoutSpec = 'layout.default="force-directed" defaultVisualStyle="Local-Red-Blue-On-White"'
netExtension = ".sif"

def usage(code=0):
    print __doc__
    if code != None: sys.exit(code)

def log(msg):
    if (verbose):
        sys.stderr.write(msg)

def main(args):
    ## Parse arguments
    try:
        opts, args = getopt.getopt(args, "c:v:p:l:q")
    except getopt.GetoptError, err:
        print str(err)
        usage(2)
    
    if len(args) != 1:
        print "incorrect number of arguments"
        usage(1)
    
    feature = args[0]
    
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
    
    ## Check structure
    assert os.path.exists("LABEL.NA")
    assert os.path.exists("TYPE.NA")
    assert os.path.exists("%s_SCORE.NA" % (feature))
    assert os.path.exists("%s" % (feature))
    
    ## Identify nets with feature
    sifFiles = list()
    for i in os.listdir("%s" % (feature)):
        if i.endswith(netExtension):
            sifFiles.append(feature+"/"+i)
                
    ## Launch cytoscape
    cmd = "%s -N %s -n LABEL.NA TYPE.NA %s_SCORE.NA -V %s -p %s -P %s" % (cysPath, " ".join(sifFiles), feature, vizPath, pluginPath, layoutSpec)
    log(cmd+"\n")
    os.system(cmd)

if __name__ == "__main__":
    main(sys.argv[1:])
