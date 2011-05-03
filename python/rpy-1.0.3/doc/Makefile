#  $Id: Makefile 299 2006-03-22 22:13:54Z warnes $
#
# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is the RPy python module.
#
# The Initial Developer of the Original Code is Walter Moreira.
# Portions created by the Initial Developer are Copyright (C) 2002
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#    Gregory R. Warnes <greg@warnes.net> (Maintainer)
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#
# ***** END LICENSE BLOCK *****

SRC = rpy.texi defs.texi

dvi: rpy.dvi
rpy.dvi: $(SRC)
	tex rpy.texi
	tex rpy.texi

info: rpy.info
rpy.info: $(SRC)
	makeinfo rpy.texi
	makeinfo rpy.texi

html: rpy_html/index.html
rpy_html/index.html: $(SRC)
	makeinfo --html rpy.texi
	makeinfo --html rpy.texi
	-rm -rf rpy_html
	mv rpy rpy_html

rpy_html_tgz: html
	tar -cvzf rpy_html.tgz rpy_html

pdf: rpy.pdf
rpy.pdf: $(SRC)
	pdftex rpy.texi
	pdftex rpy.texi

all: dvi info html pdf rpy_html_tgz

dist-clean: clean
	-rm -f rpy.dvi rpy.pdf rpy.info 
	-rm -rf rpy_html rpy_html.tgz

clean:
	-rm -f rpy.cp rpy.cps rpy.fn rpy.fns rpy.ky
	-rm -f rpy.kys rpy.log rpy.pg rpy.pgs rpy.tmp
	-rm -f rpy.toc rpy.tp rpy.tps rpy.vr rpy.vrs 
	-rm -f rpy.aux 

