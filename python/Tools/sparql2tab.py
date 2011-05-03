#!/usr/bin/python

import sys
from xml.sax import ContentHandler, make_parser

class DocHandler(ContentHandler):
    def __init__(self, out):
        self._out = out
        self._currentcol = 1
        self._colmap = {}
        self._invar = 0
    def startElement(self, name, attrs):
        if name == "variable":
            self._colmap[attrs["name"]] = self._currentcol
            self._currentcol += 1
        elif name == "bnode":
            self._out.write("_:")
            self._invar = 1
        elif name == "uri":
            self._out.write("<")
            self._invar = 1
        elif name == "literal":
            self._invar = 1
        elif name == "binding":
            col = self._colmap[attrs["name"]]
            self._out.write("\t" * (col - self._currentcol))
            self._currentcol = col
    def endElement(self, name):
        if name == "uri" or name == "bnode" or name == "literal":
            self._invar = 0
        if name == "uri":
            self._out.write(">")
        elif name == "result":
            self._out.write("\n")
            self._currentcol = 1
    def characters(self, ch):
        if self._invar == 1:
            try:
                self._out.write(ch.encode('ascii', 'xmlcharrefreplace'))
            except (LookupError):
                self._out.write(ch.encode('ascii', 'replace'))
        
dh = DocHandler(sys.stdout)
parser = make_parser()
parser.setContentHandler(dh)

parser.parse(sys.stdin)
