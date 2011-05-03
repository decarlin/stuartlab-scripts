/*
 * $Id: RPy.h 384 2007-11-30 00:40:17Z warnes $
 * Public API for calling R.
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

#ifndef _RPY_H
#define _RPY_H

#ifdef _WIN32
#  undef ERROR   /* nameclash with Rext/RS.h */
#  include <windows.h>
#  undef ERROR
#endif /*_WIN32*/

#include <R.h>
#include <Rdefines.h>
#include <Rinternals.h>
#include <Rversion.h>
#undef _POSIX_C_SOURCE
#include <Python.h>
#include <R_ext/Rdynload.h>
#include <R_ext/eventloop.h>

#ifdef _WIN32
#  define Win32  /* needed to get definition for UIMode */
#  include "rpy_Rinterface.h"
#  undef Win32
#  if R_VERSION < 0x20000
#    include <Graphics.h>
#  else
#    include <Rgraphics.h>
#  endif
#else
#  if R_VERSION < 0x20100
#    include "rpy_Rinterface.h"
#  else
#    include <Rinterface.h>
#  endif
#endif  /* _WIN32 */

#include <Rdevices.h> /* must follow Graphics.h */


/* Missing definitions from Rinterface.h or RStartup.h */
# define CleanEd		Rf_CleanEd
extern void CleanEd(void);
extern int  R_CollectWarnings; 
# define PrintWarnings		Rf_PrintWarnings
extern void PrintWarnings(void);
/****/

#include <signal.h>

#ifdef WITH_NUMERIC
# if WITH_NUMERIC == 3
#    include "numpy/arrayobject.h"
#    define PY_ARRAY_MODULE_NAME "numpy"
typedef npy_intp n_intp;
# elif WITH_NUMERIC == 1
#    include "Numeric/arrayobject.h"
#    define PY_ARRAY_MODULE_NAME "multiarray"
typedef int n_intp;
# else
#    error "unknown array variant"
# endif
#else
typedef int n_intp;
#endif
#define xstr(s) str(s)
#define str(s) #s

#include "robjobject.h"
#include "setenv.h"


#define MAXIDSIZE 256

/* Conversion */
SEXP to_Robj(PyObject *);
PyObject *to_Pyobj(SEXP);
PyObject *to_Pyobj_table(SEXP);
PyObject *to_Pyobj_with_mode(SEXP, int);

#define NO_CONVERSION 0
#define VECTOR_CONVERSION 1
#define BASIC_CONVERSION 2
#define CLASS_CONVERSION 3
#define PROC_CONVERSION 4

#define TOP_MODE 4

/* R Evaluation */
SEXP do_eval_expr(SEXP e);
SEXP do_eval_fun(char *);
SEXP get_fun_from_name(char *);

/* Three new exception */
extern PyObject *RPy_Exception;                /* Base RPy exception  */
extern PyObject *RPy_TypeConversionException;  /* R<->Python conversion errors */
extern PyObject *RPy_RException;               /* Errors from R */

const char *get_last_error_msg(void);

/* For initializing R */
extern int Rf_initEmbeddedR(int argc, char *argv[]);
extern void init_io_routines(void);

/* I/O functions */
//#ifdef _WIN32
//__declspec(dllimport) FILE *R_Outputfile;
//#else
extern FILE *R_Outputfile;
//#endif

#ifdef _WIN32
extern void RPy_WriteConsole(char *, int);
extern int  RPy_ReadConsole(char *, char *, int, int);
#endif

extern void (*ptr_R_WriteConsole)(char *, int);
extern int (*ptr_R_ReadConsole)(char *, unsigned char *, int, int);
extern int (*ptr_R_ShowFiles)(int, char **, char **, char *, int, char *);

#ifdef _WIN32
extern void R_WriteConsole(char *, int);
extern int  R_ReadConsole(char *, unsigned char *, int, int);
extern void R_ProcessEvents(void);

/* Windows R DLL Calls */
extern char *getDLLVersion();
extern void R_DefParams(Rstart);
extern void R_SetParams(Rstart);
extern void setup_term_ui(void);
extern char *getRHOME(void);
__declspec(dllimport) int UserBreak;
#endif

/* Setters for io functions */
PyObject *set_output(PyObject *self, PyObject *args);
PyObject *set_input(PyObject *self, PyObject *args);
PyObject *set_showfiles(PyObject *self, PyObject *args);
PyObject *get_output(PyObject *self, PyObject *args);
PyObject *get_input(PyObject *self, PyObject *args);
PyObject *get_showfiles(PyObject *self, PyObject *args);

/* Interrupt the R interpreter */
void interrupt_R(int);

/* The Python original SIGINT handler */
extern PyOS_sighandler_t python_sigint;

/* R function for jumping to toplevel context */
extern void jump_now(void);

/* Global interpreter */
extern PyInterpreterState *my_interp;

/* Signal whether R is running interactively */
extern int R_interact;

/* RPy namespace */
extern PyObject *rpy;

extern PyObject *rpy_dict;

/* Pause/continue the event loop */
void stop_events(void);
void start_events(void);


/* Translation functions */
extern int to_Pyobj_proc(SEXP robj, PyObject **obj);
extern int to_Pyobj_class(SEXP robj, PyObject **obj);
extern int to_Pyobj_basic(SEXP robj, PyObject **obj);
extern int to_Pyobj_vector(SEXP robj, PyObject **obj, int mode);

/* Macros for handing quoted macro variables defined via command line
   arguments to compiler. */

#define MacroQuote_(x) #x
#define MacroQuote(x) MacroQuote_(x)

#endif /* _RPY_H */
