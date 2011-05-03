from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
import os.path, time

import rpy


class InitTestCase(unittest.TestCase):

    def testInitFails(self):
        """
        R does not support multiple R interpraters.  Further, rpy
        doesn't support restarting a deleted interpreter.  So, we
        need to check that an exception is raised if someone tries
        to do either.
        """
        
        self.failUnlessRaises(RuntimeError, lambda: rpy.R() )
         
if __name__ == '__main__':
     unittest.main()
