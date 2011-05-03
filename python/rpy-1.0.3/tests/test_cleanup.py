from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
import os, os.path

class CleanupTestCase(unittest.TestCase):

    def setUp(self):
        pass
    
    def testCleanup(self):

        # run rpy in a separate process
        os.system("python testscript_cleanup.py")

        # make sure the temp dir has been removed
        tempdir = open('tempdir').read()
        self.failUnless(os.path.exists(tempdir)==False)

if __name__ == '__main__':
     unittest.main()
