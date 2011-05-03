from __future__ import nested_scopes

import unittest
import sys
try:
    from numpy import *
    ArrayLib='NumPy'
except ImportError:
    try:
        from Numeric import *
        ArrayLib='Numeric'
    except ImportError:
        print '\nNumeric not available. Skipping.\n'
        sys.exit(0)
    
import sys
sys.path.insert(1, "..")
from rpy import *

idx = r['[[']
idx.autoconvert(NO_CONVERSION)

def to_r(obj):
    # For some reason, these two lines stop working after a few
    # iterations of `testall.py --loop'.  I'm not sure why
    #    r.list.autoconvert(NO_CONVERSION) 
    #    return idx(r.list(obj),1)
    # These three lines accomplish the same thing, but more
    # doesn't stop working after a few iterations.
    f = r("function(x) x")
    f.autoconvert(NO_CONVERSION)
    return f(obj)

class ArrayTestCase(unittest.TestCase):

    def setUp(self):
        set_default_mode(NO_DEFAULT)
        py = array(range(24))
        self.py = reshape(py, (2,3,4))
        py_to_r = to_r(self.py)
        self.py_c = py_to_r.as_py()
        
        r.array.autoconvert(NO_CONVERSION)
        self.ra = r.array(range(24), dim=(2,3,4))
        ra_to_py = self.ra.as_py()
        self.ra_c = to_r(ra_to_py)
        r.array.autoconvert(PROC_CONVERSION)
        
    def testZeroDimToR(self):
        set_default_mode(NO_CONVERSION)
        a = zeros((0,7))
        ra = r.c(a)
        set_default_mode(NO_DEFAULT)
        self.failUnless(r.is_null(ra))

    def testZeroDimToPy(self):
        self.failUnless(r.array(0,dim=(0,7)) == None)
        
    def testToPyDimensions(self):
        self.failUnless(self.py_c.shape == self.py.shape,
                        'wrong dimensions in Numeric array')

    def testToRDimensions(self):
        self.failUnless(r.dim(self.ra) == r.dim(self.ra_c),
                        'wrong dimensions in R array')

    def testPyElements(self):
        self.failUnless(self.py[0,0,0] == self.py_c[0,0,0] and
                        self.py[1,2,3] == self.py_c[1,2,3] and
                        self.py[1,1,2] == self.py_c[1,1,2] and
                        self.py[1,0,3] == self.py_c[1,0,3],
                        'Numeric array not equal')

    def testRElements(self):
        try:
            idx.autoconvert(BASIC_CONVERSION)
            self.failUnless(idx(self.ra, 1,1,1) == idx(self.ra_c, 1,1,1) and
                            idx(self.ra, 2,3,4) == idx(self.ra_c, 2,3,4) and
                            idx(self.ra, 2,2,3) == idx(self.ra_c, 2,2,3) and
                            idx(self.ra, 2,1,4) == idx(self.ra_c, 2,1,4),
                            'R array not equal')
        finally:
            idx.autoconvert(NO_CONVERSION)

    def testPyOutOfBounds(self):
        self.failUnlessRaises(IndexError, lambda: self.py_c[5,5,5])

    def testROutOfBounds(self):
        self.failUnlessRaises(RPyException, lambda: idx(self.ra_c, 5,5,5))

    def test64BitIntArray(self):

        # 64 bit ints
        try:
            if(ArrayLib=='NumPy'):
                a = array( [1,2,3], 'Int64' )
            else:
                a = array( [1,2,3], Int64 )
        except:
            print "\nInt64 not found (32 bit platform?), skipping this test.\n"
            return            

        b = r.c(a)

    def test32BitIntArray(self):

        # 32 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int32' )
        else:
            a = array( [1,2,3], Int32 )

        b = r.c(a)

    def test16BitIntArray(self):

        # 16 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int16' )
        else:
            a = array( [1,2,3], Int16 )
            
        b = r.c(a)

    def test8BitIntArray(self):

        # 8 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int8' )
        else:
            a = array( [1,2,3], Int8 )

        b = r.c(a)

    def testBoolArray(self):

        # 8 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Bool' )
        else:
            print "\nBool arrays not supported by Numeric, skipping this test.\n"
            return

        b = r.c(a)

    def test64BitFloatArray(self):

        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Float64' )
        else:
            a = array( [1,2,3], Float64 )

        b = r.c(a)

    def test32BitFloatArray(self):

        # 32 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Float32' )
        else:
            a = array( [1,2,3], Float32 )

        b = r.c(a)

    def testCharArray(self):

        if(ArrayLib=='NumPy'):
            a = array( ['A', 'B', 'C'], character )
        else:
            a = array( ['A', 'B', 'C'], Character )

        self.failUnlessRaises(RPyTypeConversionException, lambda: r.c(a) )


    def testStringArray(self):

        if(ArrayLib=='NumPy'):
            a = array( ['ABCDEFHIJKLM', 'B', 'C C C'], 'S10' )
        else: # not available on Numeric
            print "\nString arrays not supported by Numeric, skipping this test.\n"
            return

        self.failUnlessRaises(RPyTypeConversionException, lambda: r.c(a) )


    def testObjArray(self):

        if(ArrayLib=='NumPy'):
            a = array( ['A','B', 'C'], 'object' )
        else:
            a = array( ['A','B', 'C'], PyObject )

        self.failUnlessRaises(RPyTypeConversionException, lambda: r.c(a) )



    def test64BitIntScalar(self):

        # 64 bit ints
        try:
            if(ArrayLib=='NumPy'):
                a = array( [1,2,3], 'Int64' )
            else:
                a = array( [1,2,3], Int64 )
        except:     
            print "\nInt64 not found (32 bit platform?), skipping this test.\n"
            return            

        b = r.c(a[0])

    def test32BitIntScalar(self):

        # 32 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int32' )
        else:
            a = array( [1,2,3], Int32 )

        b = r.c(a[0])

    def test16BitIntScalar(self):

        # 16 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int16' )
        else:
            a = array( [1,2,3], Int16 )
            
        b = r.c(a[0])

    def test8BitIntScalar(self):

        # 8 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Int8' )
        else:
            a = array( [1,2,3], Int8 )

        b = r.c(a[0])

    def testBoolScalar(self):

        # 8 bit ints
        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Bool' )
        else:
            print "\nBool arrays not supported by Numeric, skipping this test.\n"
            return

        b = r.c(a[0])

    def test64BitFloatScalar(self):

        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Float64' )
        else:
            a = array( [1,2,3], Float64 )
            
        b = r.c(a[0])

    def test32BitFloatScalar(self):

        if(ArrayLib=='NumPy'):
            a = array( [1,2,3], 'Float32' )
        else:
            a = array( [1,2,3], Float32 )

        b = r.c(a[0])

    def testCharScalar(self):

        if(ArrayLib=='NumPy'):
            a = array( ['A', 'B', 'C'], character )
            self.failUnless( r.c(a[0])=='A' )
        else:
            # RPy does not handle translation oc Numeric.Character objects
            a = array( ['A', 'B', 'C'], Character )
            self.failUnlessRaises( RPyTypeConversionException, lambda:r.c(a[0])=='A' )


    def testStringScalar(self):

        if(ArrayLib=='NumPy'):
            a = array( ['ABCDEFHIJKLM', 'B', 'C C C'], 'S10' )
            self.failUnless( r.c(a[0])=='ABCDEFHIJK' )
        else:
            # String class not available on Numeric
            print "\nString arrays not supported by Numeric, skipping this test.\n"
            return



    def testObjScalar(self):

        if(ArrayLib=='NumPy'):
            a = array( ['A', 'B', 'C'], 'object' )
        else:
            a = array( ['A', 'B', 'C'], PyObject )

        self.failUnless( r.c(a[0])=='A' )



if __name__ == '__main__':
    unittest.main()
