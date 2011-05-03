from rpy import *

class ERobj:

    def __init__(self, robj):
        self.robj = robj

    def as_r(self):
        return self.robj

    def __str__(self):
        a = with_mode(NO_CONVERSION,
                      lambda: r.textConnection('tmpobj', 'w'))()
        r.sink(file=a, type='output')
        r.print_(self.robj)
        r.sink()
        r.close_connection(a)
        str = with_mode(BASIC_CONVERSION,
			lambda: r('tmpobj'))()
	return '\n'.join(as_list(str))

    def __getattr__(self, attr):
        e = with_mode(BASIC_CONVERSION,
                      lambda: r['$'](self.robj, attr))()
        if e:
            return e
        return self.__dict__[attr]
