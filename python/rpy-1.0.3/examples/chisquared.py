# Simple script for drawing the chi-squared density
#
from rpy import *

def draw(df, start=0, end=10):
    grid = r.seq(start, end, by=0.1)
    l = [r.dchisq(x, df) for x in grid]
    r.par(ann=0, yaxt='n')
    r.plot(grid, l, type='lines')

if __name__ == '__main__':
    print "<Enter> to quit."
    while 1:
        try:
            df = int(raw_input('Degrees of freedom> '))
            draw(df)
        except ValueError:
            break
