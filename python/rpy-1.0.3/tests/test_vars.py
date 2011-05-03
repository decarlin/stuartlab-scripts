from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
import os.path, time

from rpy import *


class InitTestCase(unittest.TestCase):

    def setup(self):
        set_default_mode(NO_DEFAULT)

    def testGetVars(self):
        """
        Define and access variables in the R namespace.
        """

        r("f <- function(x) x+1")
        r.assign("x",100)
        r.assign("v",range(10))
        r.assign("d",{'a':1, 'b':2})
        
        self.failUnless( r.x == 100)
        self.failUnless( r.v == range(10))
        self.failUnless( type(r.f) == type(r.c) )
        
         
if __name__ == '__main__':
     unittest.main()
