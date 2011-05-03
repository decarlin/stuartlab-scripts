from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

class UtilityTestCase(unittest.TestCase):

    def testAsList(self):
        self.failUnless(as_list(5) == [5])
        self.failUnless(as_list(['a', 6]) == ['a', 6])
        self.failUnless(as_list([5]) == [5])
        self.failUnless(as_list((5)) == [(5)])

    def testWithMode(self):
        with_mode(NO_CONVERSION,
                  lambda: self.failUnless(get_default_mode() == NO_CONVERSION))()
        with_mode(BASIC_CONVERSION, lambda:
                  self.failUnless(get_default_mode() == BASIC_CONVERSION))()
        with_mode(CLASS_CONVERSION, lambda:
                  self.failUnless(get_default_mode() == CLASS_CONVERSION))()
        with_mode(PROC_CONVERSION, lambda:
                  self.failUnless(get_default_mode() == PROC_CONVERSION))()
        self.failUnlessRaises(ValueError, lambda: with_mode(TOP_CONVERSION+1, lambda: 4)())
        self.failUnlessRaises(ValueError, lambda: with_mode(-2, lambda: 4)())

    def testRCode(self):
        with_mode(BASIC_CONVERSION,
                  lambda: self.failUnless(r("c(4,5)") == [4,5]))()
        self.failUnlessRaises(RPyRException, lambda: r("foo"))
        self.failUnlessRaises(RPyRException, lambda: r("[$%^"))

        
if __name__ == '__main__':
    unittest.main()
