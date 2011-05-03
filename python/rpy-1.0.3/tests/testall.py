import os
import sys
import unittest
import random

import rpy


def run(module):
    try:
        unittest.main(module)
    except SystemExit:
        pass

if __name__ == '__main__':
    modules = os.listdir('.')

    if '--random' in sys.argv:
        shuffle=True
        sys.argv.remove('--random')
    else:
        shuffle=False

    if '--loop' in sys.argv:
	niter = 1000
        sys.argv.remove('--loop')
    else:
	niter = 1


    modules = filter( lambda x: not x.endswith('.pyc'), modules)
    modules = filter( lambda x: x.startswith('test_'), modules)
    modules = filter( lambda x: x.endswith('.py'), modules)

    print "Modules to be tested:", modules
    
    for iter in range(niter):
        if shuffle: random.shuffle(modules)
        for module in modules:
            name = module[:-3]
            print 'Testing:', name
            rpy.set_default_mode(rpy.NO_DEFAULT)  # reset to base case
            run(name)
