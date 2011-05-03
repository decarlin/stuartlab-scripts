from rpy import *
import erobj

class DataFrame(erobj.ERobj):
    def __init__(self, robj):
        erobj.ERobj.__init__(self, robj)

    def rows(self):
        return r.attr(self.robj, 'row.names')
    
    def __getattr__(self, attr):
        o = self.__dict__['robj']
        if attr in as_list(r.colnames(o)):
            return r['$'](o, attr)
        return self.__dict__[attr]
