/*
 * $Id: robjobject.h 299 2006-03-22 22:13:54Z warnes $
 * The Robj type
 */

/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the RPy python module.
 *
 * The Initial Developer of the Original Code is Walter Moreira.
 * Portions created by the Initial Developer are Copyright (C) 2002
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *    Gregory R. Warnes <greg@warnes.net> (Maintainer)
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */



/* The R object type */
typedef struct {
  PyObject_HEAD
  SEXP R_obj;		/* R object itself */
  int conversion;		/* 0: no conversion
				   1: basic conversion
				   2: class conversion
				   3: proc conversion */
} RobjObject;

#ifdef _WIN32
  extern PyTypeObject Robj_Type;
#else
  extern DL_IMPORT(PyTypeObject) Robj_Type;
#endif

#define Robj_Check(v)	((v)->ob_type == &Robj_Type)

RobjObject *Robj_new(SEXP, int);
