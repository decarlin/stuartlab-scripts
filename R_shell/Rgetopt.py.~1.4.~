#!/usr/bin/python
"""\
Rgetopt.py - wrapper for calling an R script from the command line, with
named arguments being turned into environment variables.  Use the
Rgetopt library in R to retrieve these arguments.

"""

import os, sys, tempfile

usage = __doc__

if (len(sys.argv) < 2):
    print usage
    sys.exit(1)
    
rscriptfile = sys.argv[1]
rscript = ""

if os.access(rscriptfile, os.R_OK):
    rscript = rscriptfile
else:
    print "Command script " + rscriptfile + " is not readable"
    sys.exit(2)

debug = len(sys.argv) > 2 and sys.argv[2] == "--debug"
if debug:
    sys.argv.remove("--debug")

#
# Insert the variables into the enviornoment
#
os.environ["RGETOPT_ARGC"]=str(len(sys.argv)-1)
for i in range(1,len(sys.argv)):
    os.environ["RGETOPT_ARGV_"+str(i)] = sys.argv[i]
os.environ["RGETOPT_ISATTY"]=str(int(os.isatty(1)))

#
# Make a temporary file, to allow outputing binary at the end of the script
#
(tmpStdOutFD, tmpStdOutName) = tempfile.mkstemp()
os.environ["RGETOPT_STDOUTONEXIT"] = tmpStdOutName

if debug:
    os.environ["RGETOPT_DEBUG"]='1'
    print "Copy the following line into R:"
    print "source('"+sys.argv[1]+"', echo=TRUE)"
    cmd = "R --vanilla -q"
else:
    cmd =  "R --vanilla --slave -f " + rscript

#
# Execute the R script
#
os.system(cmd)

#
# Output the final stdout data
#
tempout = open(tmpStdOutName, mode='rb')
sys.stdout.write(tempout.read())
os.unlink(tmpStdOutName)
