from __future__ import nested_scopes

import unittest
import os,sys
sys.path.insert(1, "..")
import os, os.path

class LapackLoadTestCase(unittest.TestCase):

    def setUp(self):
        pass
    
    def testLapackLoad(self):

       from rpy import r
       
       fi = 'logit.r'
       
       #--load the functions
       r.source(fi)
       
       #--test a example
       x =50000 
       n = [x, x-500,x+460,x-400,x-100,x-4]
       y = [12, 24, 23, 2,4,5]
       f = [2,2,2,1,1,1]
       
       jk = r.logit_1fact(n,y,f)


if __name__ == '__main__':
     unittest.main()
