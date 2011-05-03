/*
 * $Id: io.c 393 2008-01-02 17:34:28Z warnes $ 
 * Input/Output routines
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


#include "RPy.h"

#define ENTER_PY { PyThreadState* tstate = NULL;\
    if (_PyThreadState_Current == NULL) {\
       tstate = PyThreadState_New(my_interp);\
       PyEval_AcquireThread(tstate);\
    }

#define LEAVE_PY  if (tstate) {\
       PyEval_ReleaseThread(tstate);}\
    } 

PyObject *rpy_output=NULL, *rpy_input=NULL, *rpy_showfiles=NULL;

/* Show the traceback of an exception which occurred in a I/O process,
   except when the error is a KeyboardInterrupt, in which case abort
   the R interpreter */
void
RPy_ShowException()
{
  PyObject *err;

  if ((err = PyErr_Occurred())) {
    if (PyErr_GivenExceptionMatches(err, PyExc_KeyboardInterrupt)) {
      interrupt_R(0);
    }
    else {
      PyErr_WriteUnraisable(err);
      PyErr_Clear();
    }
  }
}


void
RPy_WriteConsole(char *buf, int len)
{
  PyOS_sighandler_t old_int;
  PyObject *dummy;

  /* It is necessary to restore the Python handler when using a Python
     function for I/O. */
  old_int = PyOS_getsig(SIGINT);
  PyOS_setsig(SIGINT, python_sigint);
  if (rpy_output) {
    ENTER_PY
    dummy = PyObject_CallFunction(rpy_output, "s", buf);
    Py_XDECREF(dummy);
    LEAVE_PY
  }
  signal(SIGINT, old_int);
  RPy_ShowException();
}

#ifdef _WIN32
int
RPy_ReadConsole(char *prompt, 
                char *buf, 
                int len, 
		int addtohistory)
#else
int
RPy_ReadConsole(char *prompt, 
                unsigned char *buf, 
                int len, 
		int addtohistory)
#endif
{
  PyObject *input_data;
  PyOS_sighandler_t old_int;

  if (!rpy_input)
    return 0;

  old_int = PyOS_getsig(SIGINT);
  PyOS_setsig(SIGINT, python_sigint);
  ENTER_PY
  start_events();
  input_data = PyObject_CallFunction(rpy_input, "si", prompt, len);
  stop_events();
  LEAVE_PY

  signal(SIGINT, old_int);

  RPy_ShowException();

  if (!input_data) {
    PyErr_Clear();
    return 0;
  }
  snprintf(buf, len, "%s", PyString_AsString(input_data));
  Py_DECREF(input_data);
  return 1;
}

int
RPy_ShowFiles(int nfile, char **file, char **headers, 
              char *wtitle, int del, char *pager)
{
  PyObject *pyfiles, *pyheaders, *result, *f, *h;
  PyOS_sighandler_t old_int;
  int i;

  if (rpy_showfiles==NULL)
    return 0;

  old_int = PyOS_getsig(SIGINT);
  PyOS_setsig(SIGINT, python_sigint);

  ENTER_PY

  pyfiles = PyList_New(0);
  pyheaders = PyList_New(0);
  if (!(pyfiles && pyheaders)) {
    return 0;
  }
 
  for (i=0; i<nfile; i++) {
    f = PyString_FromString(file[i]);
    h = PyString_FromString(headers[i]);
    PyList_Append(pyfiles, f);
    PyList_Append(pyheaders, h);
    Py_DECREF(f);
    Py_DECREF(h);
  }

  result = PyObject_CallFunction(rpy_showfiles, "OOsi", pyfiles, pyheaders,
                                 wtitle, del);
  Py_DECREF(pyfiles);
  Py_DECREF(pyheaders);

  signal(SIGINT, old_int);
  RPy_ShowException();

  LEAVE_PY

  if (!result) {
    PyErr_Clear();
    return 0;
  }
  Py_DECREF(result);
  return 1;
}

PyObject *
wrap_set(PyObject **var, char *name, PyObject *args)
{
  char *argformat;
  PyObject *func;

  argformat = (char *)PyMem_Malloc((strlen(name)+3)*sizeof(char));
  sprintf(argformat, "O:%s", name);
  if (!PyArg_ParseTuple(args, argformat, &func))
    return NULL;

  Py_INCREF(func);
  *var = func;
  Py_INCREF(Py_None);
  return Py_None;
}

PyObject *
set_output(PyObject *self, PyObject *args)
{
  return wrap_set(&rpy_output, "set_rpy_output", args);
}

PyObject *
set_input(PyObject *self, PyObject *args)
{
  return wrap_set(&rpy_input, "set_rpy_input", args);
}

PyObject *
set_showfiles(PyObject *self, PyObject *args)
{
  return wrap_set(&rpy_showfiles, "set_rpy_showfiles", args);
}

PyObject *
wrap_get(PyObject *o)
{
  if (o) {
    return o;
  } else {
    Py_INCREF(Py_None);
    return Py_None;
  }
}

PyObject *
get_output(PyObject *self, PyObject *args)
{
  if (!PyArg_ParseTuple(args, ":get_rpy_output"))
    return NULL;

  return wrap_get(rpy_output);
}

PyObject *
get_input(PyObject *self, PyObject *args)
{
  if (!PyArg_ParseTuple(args, ":get_rpy_input"))
    return NULL;

  return wrap_get(rpy_input);
}

PyObject *
get_showfiles(PyObject *self, PyObject *args)
{
  if (!PyArg_ParseTuple(args, ":get_rpy_showfiles"))
    return NULL;

  return wrap_get(rpy_showfiles);
}

void
init_io_routines(void)
#ifdef _WIN32
{ 
  return; 
}
#else
{
  R_Outputfile = NULL;
  ptr_R_WriteConsole = RPy_WriteConsole;
  ptr_R_ReadConsole = RPy_ReadConsole;
  ptr_R_ShowFiles = RPy_ShowFiles;
}
#endif
