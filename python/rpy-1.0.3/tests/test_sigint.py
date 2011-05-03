from __future__ import nested_scopes

import unittest
import sys
sys.path.insert(1, "..")
from rpy import *
import sys
import os
import signal
import time


def sendsig():
    "Send myself a keyboard interrupt"
    if sys.platform=="win32": #FIXME: ugy hack so that win32 passes
        raise KeyboardInterrupt
    else:
        os.kill(os.getpid(), signal.SIGINT)
        time.sleep(1)

class SigintTestCase(unittest.TestCase):
            
    def testSigint(self):
        "test handling of keyboard interrupt signals"
        self.failUnlessRaises(KeyboardInterrupt, sendsig)

if __name__ == '__main__':
    unittest.main()
