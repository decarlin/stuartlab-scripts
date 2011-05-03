from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
import os.path, time
from rpy_tools import getstatusoutput


class NonInteractiveTestCase(unittest.TestCase):

    def testNonInteractiveErrors(self):
        """
        Ensure that when rpy is used non-interactively, errors don't cause abort.
        """

        flag, message = getstatusoutput("echo 'import rpy; rpy.r(\"foobar()\")' | python")
        assert( message.find('Execution halted') ==  -1 )
         
if __name__ == '__main__':
     unittest.main()
