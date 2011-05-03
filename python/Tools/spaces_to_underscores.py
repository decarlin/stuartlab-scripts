#! /usr/bin/env python

import os
import sys

files = os.listdir("./")
for f in files:
	os.rename (f, f.replace(' ', '_'))
