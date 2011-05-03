from rpy import r
import os.path

# find out where the temp directory is
tempdir = r.tempdir()

# write its name into a file
f = open('tempdir','w')
f.write(tempdir)
f.close()

# put something there..
r.postscript(os.path.join(tempdir,"foo.ps"))
r.plot(1,1)
r.dev_off()
           
