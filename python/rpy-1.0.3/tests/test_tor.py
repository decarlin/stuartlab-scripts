from __future__ import nested_scopes

import sys
import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

def with_c(f):
    try:
        r.c.autoconvert(NO_CONVERSION)
        f()
    finally:
        r.c.autoconvert(BASIC_CONVERSION)

class foo:
    def __init__(self, x):
        self.x = x
    def as_r(self):
        return self.x

class TypeConversionToRTestCase(unittest.TestCase):

    def setup(self):
        set_default_mode(NO_DEFAULT)

    def testRobjToR(self):
        def f():
            r1 = r.c(4)
            r2 = r.c('foo')
            r3 = r.c(['a', 'b'])
            self.failUnless(r['=='](r1, 4))
            self.failUnless(r['=='](r2, 'foo'))
            self.failUnless(r['=='](r3, ['a','b']))
            # The following test for bug ID 1277392
            self.failUnless(r.typeof(r.eval) == 'closure')
            self.failUnless(r.typeof(r.eval(r.eval)) == 'closure')
            self.failUnless(r.typeof(r.eval([r.eval, r.eval])) == 'list')
        with_c(f)

    def testEmptyListToNull(self):
        self.failUnless(r.is_null([]))

    def testBooleanToRLogical(self):
        assert( r.c(True) == True)
        assert( type(r.c(True)) == type(True))

        assert( r.c(False) == False)
        assert( type(r.c(False)) == type(False))
        
    def testIntToRInt(self):
        def f():
            r1 = r.c(4)
            self.failUnless(r.typeof(r1) == 'integer')
        with_c(f)

    def testFloatToRFloat(self):
        with_c(lambda:
               self.failUnless(r.typeof(r.c(4.5)) == 'double'))

    def testCharToRChar(self):
        with_c(lambda:
               self.failUnless(r.typeof(r.c('foo')) == 'character'))

    def testDictToRNamedVector(self):
        def f():
            robj = r.c({'foo':5, 'bar':7})
            self.failUnless(r.typeof(robj) == 'integer')
            self.failUnless('foo' in r.attributes(robj)['names'] and
                            'bar' in r.attributes(robj)['names'])
        with_c(f)

    def testListToRVector(self):
        def f():
            robj = r.c(1,2,3,4)
            self.failUnless(r.length(robj) == 4)
        with_c(f)

    def testNotConvertible(self):
        self.failUnlessRaises(RPyTypeConversionException, lambda: r.c(range))

    def testInstancesNotConvertible(self):
        class Foo:
            pass
        a = Foo()
        self.failUnlessRaises(RPyTypeConversionException, lambda: r.c(a))

    def testAs_rMethod(self):
        r.c.autoconvert(BASIC_CONVERSION)
        a = foo(3)
        b = foo('foo')
        d = foo(r.seq)
        self.failUnless(r.c(a) == 3)
        self.failUnless(r.c(b) == 'foo')
        self.failUnless(r.c(d)(1,3) == [1,2,3])

    def testNAFromR(self):
        ''' R defines NA value (currently from limits.h MAX_INT)
        For 64 bit systems this will not be the same as sys.maxint
        '''
        with_mode(BASIC_CONVERSION,
                  lambda: self.failUnless(r.is_na(r.NA)))()

    def testInfToR(self):
        with_mode(BASIC_CONVERSION, lambda:
                  self.failUnless(r.is_infinite(r.log(0))))()

    def testNaNToR(self):
        with_mode(BASIC_CONVERSION, lambda:
                  self.failUnless(r.is_nan(r.log(-1))))()
        
if __name__ == '__main__':
    unittest.main()
