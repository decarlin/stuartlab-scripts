/*
 * $Id: R_eval.c 363 2007-11-12 23:27:48Z warnes $ 
 * Evaluation of R expressions.
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
/*
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *
 *  Evaluation of R expressions.
 *
 *  $Id: R_eval.c 363 2007-11-12 23:27:48Z warnes $
 *
 */

#include <RPy.h>

/* The Python original SIGINT handler */
PyOS_sighandler_t python_sigint;

/* Indicates whether the R interpreter was interrupted by a SIGINT */
int interrupted = 0;

/* Abort the current R computation due to a SIGINT */
void interrupt_R(int signum)
{
  interrupted = 1;
  error("Interrupted");
}


/* Evaluate a SEXP. It must be constructed by hand. It raises a Python
   exception if an error ocurred in the evaluation */
SEXP do_eval_expr(SEXP e) {
  SEXP res;
  int error = 0;
  PyOS_sighandler_t old_int;

  /* Enable our handler for SIGINT inside the R
     interpreter. Otherwise, we cannot stop R calculations, since
     SIGINT is only processed between Python bytecodes. Also, save the
     Python SIGINT handler because it is necessary to temporally
     restore it in user defined I/O Python functions. */
  stop_events();

  #ifdef _WIN32
    old_int = PyOS_getsig(SIGBREAK);
  #else
    old_int = PyOS_getsig(SIGINT);
  #endif
  python_sigint = old_int;

  signal(SIGINT, interrupt_R);

  interrupted = 0;
  res = R_tryEval(e, R_GlobalEnv, &error);

  #ifdef _WIN32
    PyOS_setsig(SIGBREAK, old_int);   
  #else 
    PyOS_setsig(SIGINT, old_int);
  #endif

  start_events();

  if (error) {
    if (interrupted) {
      PyErr_SetNone(PyExc_KeyboardInterrupt);
    }
    else
      PyErr_SetString(RPy_RException, get_last_error_msg());
    return NULL;
  }


  return res;
}

/* Evaluate a function given by a name (without arguments) */
SEXP do_eval_fun(char *name) {
  SEXP exp, fun, res;

  fun = get_fun_from_name(name);
  if (!fun)
    return NULL;

  PROTECT(fun);
  PROTECT(exp = allocVector(LANGSXP, 1));
  SETCAR(exp, fun);

  PROTECT(res = do_eval_expr(exp));
  UNPROTECT(3);
  return res;
}

/*
 * Get an R **function** object by its name. When not found, an exception is
 * raised. The checking of the length of the identifier is needed to
 * avoid R raising an error causing Python to  dump core.
 */
SEXP get_fun_from_name(char *ident) {
  SEXP obj;

  /* For R not to throw an error, we must check the identifier is
     neither null nor greater than MAXIDSIZE */
  if (!*ident) {
    PyErr_SetString(RPy_Exception, "attempt to use zero-length variable name");
    return NULL;
  }
  if (strlen(ident) > MAXIDSIZE) {
    PyErr_SetString(RPy_Exception, "symbol print-name too long");
    return NULL;
  }
  
#if R_VERSION < 0x20000
  obj = Rf_findVar(Rf_install(ident), R_GlobalEnv);
#else
  /*
   * For R-2.0.0 and later, it is necessary to use findFun to get
   * functions.  Unfortunately, calling findFun on an undefined name
   * causes a segfault!
   *
   * Solution:
   *
   * 1) Call findVar on the name
   *
   * 2) If something has the name, call findFun
   *
   * 3) Raise an error if either step 1 or 2 fails.
   */
  obj = Rf_findVar(Rf_install(ident), R_GlobalEnv);

  if (obj != R_UnboundValue)
      obj = Rf_findFun(Rf_install(ident), R_GlobalEnv);
#endif
  
  if (obj == R_UnboundValue) {
    PyErr_Format(RPy_Exception, "R Function \"%s\" not found", ident);
    return NULL;
  }
  return obj;
}

/* Obtain the text of the last R error message */
const char *get_last_error_msg() {
  SEXP msg;

  msg = do_eval_fun("geterrmessage");
  return CHARACTER_VALUE(msg);
}
