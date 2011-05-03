from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

idx = r['[[']
idx.autoconvert(BASIC_CONVERSION)

def to_r(obj):
    r.list.autoconvert(NO_CONVERSION)
    idx.autoconvert(NO_CONVERSION)
    o = idx(r.list(obj),1)
    idx.autoconvert(BASIC_CONVERSION)
    return o

def all_equal_3d(vec1, vec2):
    
    if len(vec1) != len(vec2): return False
    
    for i in range(len(vec1)):
        
        if len(vec1[i]) != len(vec2[i]): return False
        
        for j in range( len(vec1[i]) ):
            
            if len(vec1[i][j])!=len(vec2[i][j]): return False

            for k in range( len(vec1[i][j]) ):
                
                if vec1[i][j][k] != vec2[i][j][k]: return False

            
    return True
 

class ArrayTestCase(unittest.TestCase):

    def setUp(self):
        self.py = [[[0,6,12,18],[2,8,14,20],[4,10,16,22]],
                   [[1,7,13,19],[3,9,15,21],[5,11,17,23]]]
        set_default_mode(NO_DEFAULT)
        try:
            r.array.autoconvert(NO_CONVERSION)
            self.ra = r.array(range(24),dim=(2,3,4))
        finally:
            r.array.autoconvert(BASIC_CONVERSION)

    def testConversionToPy(self):
        self.failUnless(all_equal_3d(self.py,self.ra.as_py()),
                        'wrong conversion to Python')

    def testConversionToR(self):
        py_c = to_r(self.py)
        self.failUnless(r.all_equal(self.ra, py_c),
                        'R array not equal')
        
    def testDimensions(self):
        self.failUnless(r.dim(self.ra) == [len(self.py), len(self.py[0]),
                                           len(self.py[0][0])],
                        'wrong dimensions')

    def testElements(self):
        msg = 'Numeric array not equal'
        self.failUnless(self.py[0][0][0] == idx(self.ra, 1,1,1), msg)
        self.failUnless(self.py[1][2][3] == idx(self.ra, 2,3,4), msg)
        self.failUnless(self.py[1][1][2] == idx(self.ra, 2,2,3), msg)
        self.failUnless(self.py[1][0][3] == idx(self.ra, 2,1,4), msg)

    def testPyOutOfBounds(self):
        self.failUnlessRaises(IndexError, lambda: self.py[5][5][5])
                           
    def testROutOfBounds(self):
        self.failUnlessRaises(RPyException, lambda: idx(self.ra, 5,5,5))

    def testBigArray(self):
        a = r.array(range(100000), dim=(100,1000))
        self.failUnless(a[10][10] and a[80][900])
        
if __name__ == '__main__':
    unittest.main()
