from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *
import sys


class BooleanTestCase(unittest.TestCase):

    def setup(self):
        set_default_mode(NO_DEFAULT)

    def testTRUE(self):
        self.failUnless(r.typeof(r.TRUE) == 'logical' and
                        r.as_logical(r.TRUE))

    def testFALSE(self):
        self.failUnless(r.typeof(r.FALSE) == 'logical' and
                        not r.as_logical(r.FALSE))

if __name__ == '__main__':
    unittest.main()
