from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *

class DummyOut:
    def write(self, *args, **kwds):
        pass

class IOTestCase(unittest.TestCase):

    def setUp(self):
        sys.stdout = sys.stderr = DummyOut()

    def tearDown(self):
        sys.stdout = sys.__stdout__
        sys.stderr = sys.__stderr__
        # reset i/o defaults
        set_rpy_output(rpy_io.rpy_output)
        set_rpy_input(rpy_io.rpy_input)

            
    def testIOstdin(self):
        def dummy(prompt, n):
            return prompt+'\n'
        
        set_rpy_input(dummy)
        self.failUnless(r.readline('foo') == 'foo')
        
    def testIOstdout(self):
        out = []
        def dummy(s):
            out.append(s)

        set_rpy_output(dummy)
        r.print_(5)
        self.failUnless(out == ['[1]', ' 5', '\n'])

    def testIOshowfiles(self):
        if sys.platform != 'win32':
            out = []
            def dummy(files, headers, title, delete):
                out.append('foo')
                print "Names curently defined"
                dir()            
                set_rpy_showfiles(dummy)
                r.help()
                self.failUnless(out == ['foo'])

    def testIOstdoutException(self):
        def stdout(s):
            raise Exception

        set_rpy_output(stdout)
        self.assert_(r.print_(5))

    def testIOstdinException(self):
        def stdin(prompt, n):
            raise Exception

        set_rpy_input(stdin)
        self.assert_(r.readline() == '')
        
    def testIOshowfilesException(self):
        if sys.platform != 'win32':
            def showfiles(files, headers, title, delete):
                raise Exception

            set_rpy_showfiles(showfiles)
            self.assert_(r.help() == None)
        
if __name__ == '__main__':
    unittest.main()
