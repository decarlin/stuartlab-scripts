from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

class RobjTestCase(unittest.TestCase):

    def setUp(self):
        self.robj = type(r.array)
        set_default_mode(NO_DEFAULT)
        class_table.clear()
        proc_table.clear()
        
    def testType(self):
        self.failUnless(type(r.array) == type(r.seq))

    def testCall(self):
        self.failUnless(callable(r.seq))

    def testGetItem(self):
        r.seq.autoconvert(NO_CONVERSION)
        step = 10
        pySeq = range(10, 50+step, step)
        d = r.seq(10, 50, by = step)
        for i in range(len(pySeq)):
            self.failUnless(pySeq[i] == d[i])
        self.failUnless(pySeq[-1] == d[-1])

    def testGetItemSlice(self):
        r.seq.autoconvert(NO_CONVERSION)
        step = 10
        pySeq = range(10, 50+step, step)
        d = r.seq(10, 50, by=step)
        self.failUnless(pySeq[0:4] == d[0:4])
        self.failUnless(pySeq[:4] == d[:4])
        self.failUnless(pySeq[1:] == d[1:])
        self.failUnless(pySeq[2:5] == d[2:5])
        # FIXME:
        # The one below deserves attention: a one-element slice
        # should return a one-element sequence.
        # However, the conversion system in RPy is making it 
        # somewhat problematic (or is it me ?)-- Laurent
        # self.failUnless(pySeq[0:1] == d[0:1])
        self.failUnlessRaises(IndexError, d.__getslice__, -1, 2)
        self.failUnlessRaises(IndexError, d.__getslice__, 5, 2)

    def testKeywordParameters(self):
        r.list.autoconvert(BASIC_CONVERSION)
        d = r.list(foo='foo', bar_foo='bar.foo',
                   print_='print', as_data_frame='as.data.frame')
        for k in d.keys():
            #print k, d[k]
            self.failUnless(k == d[k])
            
    def testBadKeywordParameters(self):
        def badkwname():
            # Normally, the python C API catches this, but rpymodule does it's
            # own keyword arg processing, and inadequate error checking meant
            # rpy was dereferencing a null pointer.
            r.list(**{None: 1})
        self.failUnlessRaises(TypeError, badkwname)

    def testBadKeywordDict(self):
        # This happens if the user accidently passes an object that is
        # superficially like a dictionary, but the object returned by it's
        # items() method raises an exception when fetching items. A missed
        # error check meant rpymodule was dereferencing a null pointer.
        class A(dict):
            def items(self):
                return B()
        class B(list):
            def __getitem__(self, n):
                raise TypeError
        def badkwdict():
            r.list(**A(x=1))
        self.failUnlessRaises(TypeError, badkwdict)

    def testNameConversions(self):
        self.failUnless(r.array is r['array'] and
                        r.print_ is r['print'] and
                        r.as_data_frame is r['as.data.frame'] and
                        r.attr__ is r['attr<-'])

    def testNotFound(self):
        self.failUnlessRaises(RPyException, lambda: r.foo)
        
    def testNameLengthOne(self):
        self.failUnless(r.T)

    def testAutoconvert(self):
        r.seq.autoconvert(1)
        self.failUnless(r.seq(10) == range(1,11))
        r.seq.autoconvert(NO_CONVERSION)
        self.failUnless(type(r.seq(10)) == type(r.seq))
        r.seq.autoconvert(BASIC_CONVERSION)

    def testBadAutoconvert(self):
        self.failUnlessRaises(ValueError, lambda : r.seq.autoconvert(TOP_CONVERSION+1))
        
    def testGetAutoconvert(self):
        a = r.seq.autoconvert()
        self.failUnless(type(a) is type(1) and -1<=a<=2)
        
    def testRgc(self):
        r.seq.autoconvert(NO_CONVERSION)
        a = r.seq(100000)
        r.gc()
        assert(a[10])
        r.seq.autoconvert(BASIC_CONVERSION)

    def testLCall(self):
        "Test if lcall preserves named argument ordering."
        set_default_mode(NO_CONVERSION)
        a = r.c.lcall( (('',0),('a',1),('b',2),('c',3)) )
        set_default_mode(BASIC_CONVERSION)
        self.failUnless(r.names(a) == ['','a','b','c'])

if __name__ == '__main__':
    unittest.main()
