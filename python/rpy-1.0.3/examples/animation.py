# Make a simple animation with the chi-squared density
#
import chisquared
import time
from rpy import *

def anim(from_=1, to=30, pause=0.5):
    for i in range(from_, to+1):
        r.par(yaxt='n')
        chisquared.draw(i)
        time.sleep(pause)

if __name__ == '__main__':
    anim()
