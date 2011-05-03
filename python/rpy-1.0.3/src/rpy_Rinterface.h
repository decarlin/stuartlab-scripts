/*
 * $Id: rpy_Rinterface.h 299 2006-03-22 22:13:54Z warnes $
 * This header file is to provide hooks for external GUIs such as
   GNOME and Cocoa.  It is only used on Unix-alikes
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


#ifndef RINTERFACE_H_
#define RINTERFACE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <R_ext/Boolean.h>
  
#ifdef _WIN32
#  if R_VERSION > 0x20010
#     include <R_ext/RStartup.h>
#  else
#     include "rpy_Startup.h"
#  endif
#else
#  if R_VERSION < 0x20100
#    include "rpy_Startup.h"
#  else
#    include <RStartup.h>
#  endif
#endif

/* from Defn.h */
/* this duplication will be removed in due course */

extern Rboolean R_Interactive;	/* TRUE during interactive use*/
extern Rboolean	R_Quiet;	/* Be as quiet as possible */
extern Rboolean	R_Slave;	/* Run as a slave process */
extern Rboolean	R_Verbose;	/* Be verbose */

extern void R_RestoreGlobalEnv(void);
extern void R_RestoreGlobalEnvFromFile(const char *, Rboolean);
extern void R_SaveGlobalEnv(void);
extern void R_SaveGlobalEnvToFile(const char *);
extern void R_FlushConsole(void);
extern void R_ClearerrConsole(void);
extern void R_Suicide(char*);
extern char* R_HomeDir(void);
extern int R_DirtyImage;	/* Current image dirty */
extern char* R_GUIType;
extern void R_setupHistory();
extern char* R_HistoryFile;	/* Name of the history file */
extern int R_HistorySize;	/* Size of the history file */
extern int R_RestoreHistory;	/* restore the history file? */
extern char* R_Home;		    /* Root of the R tree */

# define jump_to_toplevel	Rf_jump_to_toplevel
# define mainloop		Rf_mainloop
# define onintr			Rf_onintr
void jump_to_toplevel(void);
void mainloop(void);
void onintr();
#ifndef DEFN_H_
extern void* R_GlobalContext;    /* Need opaque pointer type for export */
#endif

void process_site_Renviron();
void process_system_Renviron();
void process_user_Renviron();

#include <stdio.h>
extern FILE * R_Consolefile;
extern FILE * R_Outputfile;


/* in sys-unix.c */
void R_setStartTime(void);
void fpu_setup(Rboolean);

/* formerly in src/unix/devUI.h */

#ifdef R_INTERFACE_PTRS
#include <Rinternals.h>

#ifdef __SYSTEM__
# define extern
#endif

extern void (*ptr_R_Suicide)(char *);
extern void (*ptr_R_ShowMessage)(char *);
extern int  (*ptr_R_ReadConsole)(char *, unsigned char *, int, int);
extern void (*ptr_R_WriteConsole)(char *, int);
extern void (*ptr_R_ResetConsole)();
extern void (*ptr_R_FlushConsole)();
extern void (*ptr_R_ClearerrConsole)();
extern void (*ptr_R_Busy)(int);
extern void (*ptr_R_CleanUp)(SA_TYPE, int, int);
extern int  (*ptr_R_ShowFiles)(int, char **, char **, char *, Rboolean, char *);
extern int  (*ptr_R_ChooseFile)(int, char *, int);
extern int  (*ptr_R_EditFile)(char *);
extern void (*ptr_R_loadhistory)(SEXP, SEXP, SEXP, SEXP);
extern void (*ptr_R_savehistory)(SEXP, SEXP, SEXP, SEXP);
extern int  (*R_timeout_handler)();
extern long R_timeout_val;

#ifdef HAVE_AQUA
extern int  (*ptr_R_EditFiles)(int, char **, char **, char *);
#endif

#endif

#ifdef __SYSTEM__
# undef extern
#endif

#ifdef __cplusplus
}
#endif

#endif /* RINTERFACE_H_ */
