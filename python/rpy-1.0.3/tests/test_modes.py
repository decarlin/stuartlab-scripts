from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

# only needed when debugging 
#import gc
#gc.set_debug(gc.DEBUG_LEAK)

class ModeConversionTestCase(unittest.TestCase):
    def setUp(self):
        set_default_mode(NO_DEFAULT)
        
    def testAs_pyArgs(self):
        self.failUnlessRaises(ValueError, lambda: r.seq.as_py(TOP_CONVERSION+1))
        self.failUnlessRaises(ValueError, lambda: r.seq.as_py(-2))
        self.failUnlessRaises(TypeError, lambda: r.seq.as_py('foo'))
        
    def testAs_py(self):
        try:
            r.c.autoconvert(NO_CONVERSION)
            a = r.c(4)
            assert(a.as_py() == 4)
            assert(a.as_py(PROC_CONVERSION) == 4)
            assert(a.as_py(BASIC_CONVERSION) == 4)
            assert(a.as_py(VECTOR_CONVERSION) == [4])
            assert(r['=='](a.as_py(NO_CONVERSION), a))
        finally:
            r.c.autoconvert(PROC_CONVERSION)

    def testAs_pyDefaultArg(self):
        set_default_mode(NO_CONVERSION)
        a = r.seq(1,3)
        b = r.t_test([1,2,3])
        assert(type(a.as_py()) == type(a))
        set_default_mode(BASIC_CONVERSION)
        assert(a.as_py() == [1,2,3])
        set_default_mode(VECTOR_CONVERSION)
        assert(a.as_py() == [1,2,3])
        class_table['htest'] = lambda o: 5
        set_default_mode(PROC_CONVERSION)
        assert(b.as_py() == 5)
        set_default_mode(NO_DEFAULT)
        
    def testDefaultModes(self):
        set_default_mode(PROC_CONVERSION)
        assert(get_default_mode() == PROC_CONVERSION)
        set_default_mode(CLASS_CONVERSION)
        assert(get_default_mode() == CLASS_CONVERSION)
        set_default_mode(BASIC_CONVERSION)
        assert(get_default_mode() == BASIC_CONVERSION)
        set_default_mode(VECTOR_CONVERSION)
        assert(get_default_mode() == VECTOR_CONVERSION)
        set_default_mode(NO_CONVERSION)
        assert(get_default_mode() == NO_CONVERSION)
        set_default_mode(NO_DEFAULT)
        assert(get_default_mode() == NO_DEFAULT)

    def testBadModes(self):
        self.failUnlessRaises(ValueError, lambda: set_default_mode(-2))
        self.failUnlessRaises(ValueError, lambda: set_default_mode(TOP_CONVERSION+1))
        
    def testNoDefaultMode(self):
        set_default_mode(NO_DEFAULT)
        r.t_test.autoconvert(CLASS_CONVERSION)
        r.array.autoconvert(NO_CONVERSION)
        r.seq.autoconvert(BASIC_CONVERSION)
        assert(type(r.array(1,3)) == type(r.array))
        assert(r.seq(1,3) == [1,2,3])
        class_table['htest'] = lambda o: 5
        assert(r.t_test([1,2,3]) == 5)

    def testIndividualConversions(self):
        r.c.autoconvert(BASIC_CONVERSION)
        r.seq.autoconvert(PROC_CONVERSION)
        r.min.autoconvert(VECTOR_CONVERSION)

        set_default_mode(NO_CONVERSION)
        assert(type(r.c(4)) == type(r.c))
        assert(type(r.seq(1,3)) == type(r.seq))
        assert(type(r.min(1,3)) == type(r.min))
        
        set_default_mode(NO_DEFAULT)
        assert(r.c.autoconvert() == BASIC_CONVERSION)
        assert(r.seq.autoconvert() == PROC_CONVERSION)
        assert(r.min.autoconvert() == VECTOR_CONVERSION)
        assert(r.c(4) == 4)
        assert(r.seq(1,3) == [1,2,3])
        assert(r.min(1,3) == [1])

        set_default_mode(BASIC_CONVERSION)
        assert(r.c.autoconvert() == BASIC_CONVERSION)
        assert(r.seq.autoconvert() == PROC_CONVERSION)
        assert(r.min.autoconvert() == VECTOR_CONVERSION)
        assert(r.c(4) == 4)
        assert(r.seq(1,3) == [1,2,3])
        assert(r.min(1,3) == 1)

        set_default_mode(VECTOR_CONVERSION)
        assert(r.c.autoconvert() == BASIC_CONVERSION)
        assert(r.seq.autoconvert() == PROC_CONVERSION)
        assert(r.min.autoconvert() == VECTOR_CONVERSION)
        assert(r.c(4) == [4])
        assert(r.seq(1,3) == [1,2,3])
        assert(r.min(1,3) == [1])
        
    def testVectorConversion(self):
        set_default_mode(VECTOR_CONVERSION)
        assert( r.c(True) == [True] )
        assert( r.c(4) == [4] )
        assert( r.c('A') == ['A'] )
        assert( r.c(1,'A',2) == ['1','A','2'] )
        assert( r.c(a=1, b='A', c=2) == {'a':'1', 'b':'A', 'c':'2'} )
        assert( r.list(a=1, b='A', c=2) == {'a': [1], 'c': [2], 'b': ['A']} )
        assert( type(r('x ~ y')) == type(r.c) )

    def testBasicConversion(self):
        set_default_mode(BASIC_CONVERSION)
        assert( r.c(True) == True )
        assert( r.c(4) == 4 )
        assert( r.c('A') == 'A' )
        assert( r.c(1,'A',2) == ['1','A','2'] )
        assert( r.c(a=1, b='A', c=2) == {'a':'1', 'b':'A', 'c':'2'} )
        assert( r.list(a=1, b='A', c=2) == {'a': 1, 'c': 2, 'b': 'A'} )
        assert( type(r('x ~ y')) == type(r.c) )


    def testClassTable(self):
        def f(o):
            if len(r['[['](o, 1)) > 2:
                return 5
            else:
                return 'bar'
        class_table.clear()
        class_table['htest'] = lambda o: 'htest'
        class_table['data.frame'] = f
        set_default_mode(CLASS_CONVERSION)
        assert(r.t_test([1,2,3]) == 'htest')
        assert(r.as_data_frame([1,2,3]) == 5)
        assert(r.as_data_frame([1,2]) == 'bar')
        set_default_mode(NO_DEFAULT)

    def testMultipleClassTable(self):
        set_default_mode(NO_CONVERSION)
        f = r.class__(r.c(4), 'foo')
        g = r.class__(r.c(4), ('bar', 'foo'))
        class_table['foo'] = lambda o: 'foo'
        class_table['bar'] = lambda o: 'bar'
        class_table[('bar', 'foo')] = lambda o: 5
        set_default_mode(CLASS_CONVERSION)
        assert(f.as_py() == 'foo')
        assert(g.as_py() == 5)
        del class_table[('bar','foo')]
        assert(g.as_py() == 'bar')
        del class_table['bar']
        assert(g.as_py() == 'foo')
        set_default_mode(NO_DEFAULT)
        class_table.clear()
        proc_table.clear()
        
    def testProcTable(self):
        def f(o):
            return r['$'](o, 'alternative')
        def t(o):
            e = r.attr(o, 'names')
            if e =='alternative' or \
               (type(e)==type([]) and 'alternative' in e):
                return 1
            return 0
        proc_table.clear()
        class_table.clear()
        proc_table[t] = f
        set_default_mode(NO_DEFAULT)
        r.t_test.autoconvert(PROC_CONVERSION)
        assert(r.t_test([1,2,3]) == 'two.sided')
        proc_table.clear()
        class_table.clear()
    
def main():
    unittest.main(__name__)
    
if __name__ == '__main__':
    main()
