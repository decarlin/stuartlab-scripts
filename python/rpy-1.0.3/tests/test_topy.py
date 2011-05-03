from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

# For testing the array conversion, try 'test-numeric.py' and
# 'test-array.py' depending on whether you have Numeric or not.
class TypeConversionToPyTestCase(unittest.TestCase):
    def setUp(self):
        set_default_mode(NO_DEFAULT)
        r.seq.autoconvert(BASIC_CONVERSION)
        r.c.autoconvert(BASIC_CONVERSION)
        
    def testNullToNone(self):
        assert(r.attributes(r.seq) is None)

    def testFactorToList(self):
        assert(r.factor([1,2,3,4]) == ['1','2','3','4'])
        assert(r.factor([1,1,1,2]) == ['1','1','1','2'])
        assert(r.factor(['a','b','c']) == ['a','b','c'])

    def testNAint(self):
        assert(r.NA == -2147483648)
        assert(r.is_na(r.NA))
        assert( r(-2147483648) == r.NA )

    def testNAreal(self):
        assert(repr(r.NAN) == repr(r("as.numeric(NA)")) )

    def testNAstring(self):
        assert(r("as.character(NA)") == 'NA')
        assert(r.as_character(r.NA) == 'NA') 
        assert(r.as_character(r.NAN) == 'NA')

    def testFactorNA(self):
        assert(r.factor(r.NA)=='NA')   # int
        assert(r.factor(r.NAN)=='NA')  # double
        assert(r.factor(r("as.character(NA)"))=='NA') # string
        
        xi = [1,2,r.NA,r.NAN,4]
        assert(r.factor(xi) == ['1','2','NA','NA','4'])

        xd = [1.01,2.02,r.NA,r.NAN,4.04]
        assert(r.factor(xd) == ['1.01','2.02','NA','NA','4.04'])

    def testNAList(self):
        xi = [1,2,r.NA,r.NAN,4]
        assert(r.as_character(xi) == ['1', '2', 'NA', 'NA', '4'])
        assert(repr(r.as_numeric(xi)) == repr([1.0, 2.0, r.NAN, r.NAN, 4.0]))
        assert(repr(r.as_integer(xi)) == repr([1, 2, r.NA, r.NA, 4]))
        assert(r.as_factor(xi) == ['1', '2', 'NA', 'NA', '4'])
        assert(r.is_na(xi) == [False, False, True, True, False] )

        xd = [1.01,2.02,r.NA,r.NAN,4.04]
        assert(r.as_character(xd) == ['1.01', '2.02', 'NA', 'NA', '4.04'])
        assert(repr(r.as_numeric(xd)) == repr([1.01, 2.02, r.NAN, r.NAN, 4.04]))
        assert(r.as_integer(xd) == [1, 2, r.NA, r.NA, 4])
        assert(r.as_factor(xd) == ['1.01', '2.02', 'NA', 'NA', '4.04'])
        assert(r.is_na(xd) == [False, False, True, True, False] )

    def testDataFrameToList(self):
        r.read_table.autoconvert(BASIC_CONVERSION)
        assert(r.read_table('table.txt', header=1) ==
               {'A': ['X1', 'X2', 'X3'], 'C': [5, 8, 2],
                'B': [4.0, 7.0, 6.0], 'D': ['6', '9', 'Foo']})

    def testLogicalToBoolean(self):
        assert( r('TRUE') == True)
        assert( r('T') == True )
        assert( type(r('TRUE')) == type(True))
        assert( type(r('T')) == type(True))

        assert( r('FALSE') == False)
        assert( r('F') == False )
        assert( type(r('FALSE')) == type(False))
        assert( type(r('F')) == type(False))

    def testIntToInt(self):
        assert(r.as_integer(5) == 5 and
               r.as_integer(-3) == -3)

    def testFloatToFloat(self):
        assert(r.as_real(5) == 5.0 and r.as_real(3.1) == 3.1)

    def testCplxToCplx(self):
        assert(r.as_complex(1+2j) == 1+2j and
               r.as_complex(1.5-3.4j) == 1.5-3.4j)

    def testStrToStr(self):
        r.as_data_frame.autoconvert(NO_CONVERSION)
        assert(r.class_(r.as_data_frame([1,2,3])) == 'data.frame')
        r.as_data_frame.autoconvert(BASIC_CONVERSION)

    def testVectorLengthOne(self):
        assert(r.c(1) == 1)
        assert(r.c('foo') == 'foo')
        
    def testIntVectorToList(self):
        assert(r.seq(10) == [1,2,3,4,5,6,7,8,9,10])

    def testFloatVectorToList(self):
        assert(r.seq(1,2,by=0.5) == [1.0, 1.5, 2.0])

    def testCplxVectorToList(self):
        assert(r.c(1+2j, 2-3j) == [1+2j, 2-3j])

    def testStrVectorToList(self):
        assert(r.c('Foo', 'Bar') == ['Foo', 'Bar'])

    def testListToList(self):
        r.list.autoconvert(BASIC_CONVERSION)
        assert(r.list(1,2.0,'foo') == [1, 2.0, 'foo'])
        
    def testNamedVectorToDict(self):
        r.c.autoconvert(NO_CONVERSION)
        a = r.attr__(r.c(1,2,3), 'names', ['foo', 'bar', 'baz'])
        r.c.autoconvert(BASIC_CONVERSION)
        assert(a == {'foo':1, 'bar':2, 'baz':3})

    def testVectorCoercion(self):
        r.c.autoconvert(NO_CONVERSION)
        assert(r.typeof(r.c(1,2,3)) == 'integer')
        assert(r.typeof(r.c(1,2.0,3)) == 'double')
        assert(r.typeof(r.c(1,2+3j,3)) == 'complex')
        assert(r.typeof(r.c(2,'bar',3.5)) == 'character')
        r.c.autoconvert(BASIC_CONVERSION)


if __name__ == '__main__':
    unittest.main()
