# This Makefile is for the libgd extension to perl.
#
# It was generated automatically by MakeMaker version
# 5.45 (Revision: 1.222) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: (q[LIB=/fiery/u6/jstuart/develop/perl/xlib])
#
#   MakeMaker Parameters:

#	C => [q[gdfontg.c], q[gdfontmb.c], q[gdfontt.c], q[gdfontl.c], q[gdfonts.c], q[libgd.c]]
#	H => [q[gd.h], q[gdfontl.h], q[gdfonts.h], q[io.h], q[gdfontg.h], q[gdfontmb.h], q[gdfontt.h], q[mtables.h]]
#	LINKTYPE => q[static]
#	NAME => q[libgd]
#	OBJECT => q[$(O_FILES)]
#	SKIP => [q[dynamic], q[test]]
#	clean => { FILES=>q[libgd$(LIB_EXT)] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/perl5/5.6.1/i386-linux/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -rdynamic
DLEXT = so
DLSRC = dl_dlopen.xs
LD = gcc
LDDLFLAGS = -shared -L/usr/local/lib
LDFLAGS =  -L/usr/local/lib
LIBC = /lib/libc-2.2.5.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.4.17-0.13smp
RANLIB = :
SO = so
EXE_EXT = 
FULL_AR = /usr/bin/ar


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
NAME = libgd
DISTNAME = libgd
NAME_SYM = libgd
VERSION = 0.10
VERSION_SYM = 0_10
XS_VERSION = 0.10
INST_BIN = ../blib/bin
INST_EXE = ../blib/script
INST_LIB = ../blib/lib
INST_ARCHLIB = ../blib/arch
INST_SCRIPT = ../blib/script
PREFIX = /usr
SITEPREFIX = $(PREFIX)
VENDORPREFIX = $(PREFIX)
INSTALLDIRS = site
INSTALLPRIVLIB = $(PREFIX)/lib/perl5/5.6.1
INSTALLARCHLIB = $(PREFIX)/lib/perl5/5.6.1/i386-linux
INSTALLSITELIB = $(SITEPREFIX)/lib/perl5/site_perl/5.6.1
INSTALLSITEARCH = $(SITEPREFIX)/lib/perl5/site_perl/5.6.1/i386-linux
INSTALLVENDORLIB = $(VENDORPREFIX)/lib/perl5/vendor_perl/5.6.1
INSTALLVENDORARCH = $(VENDORPREFIX)/lib/perl5/vendor_perl/5.6.1/i386-linux
INSTALLBIN = $(PREFIX)/bin
INSTALLSCRIPT = $(PREFIX)/bin
INSTALLSITEBIN = $(SITEPREFIX)/bin
PERL_LIB = /usr/lib/perl5/5.6.1
PERL_ARCHLIB = /usr/lib/perl5/5.6.1/i386-linux
SITELIBEXP = /usr/lib/perl5/site_perl/5.6.1
SITEARCHEXP = /usr/lib/perl5/site_perl/5.6.1/i386-linux
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/perl5/5.6.1/i386-linux/CORE
PERL = /usr/bin/perl
FULLPERL = /usr/bin/perl
FULL_AR = /usr/bin/ar

VERSION_MACRO = VERSION
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc

MAKEMAKER = /usr/lib/perl5/5.6.1/ExtUtils/MakeMaker.pm
MM_VERSION = 5.45

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# ROOTEXT = Directory part of FULLEXT with leading slash (eg /DBD)  !!! Deprecated from MM 5.32  !!!
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = libgd
BASEEXT = libgd
DLBASE = $(BASEEXT)
OBJECT = $(O_FILES)
LDFROM = $(OBJECT)
LINKTYPE = static

# Handy lists of source code files:
XS_FILES= 
C_FILES = gdfontg.c \
	gdfontmb.c \
	gdfontt.c \
	gdfontl.c \
	gdfonts.c \
	libgd.c
O_FILES = gdfontg.o \
	gdfontmb.o \
	gdfontt.o \
	gdfontl.o \
	gdfonts.o \
	libgd.o
H_FILES = gd.h \
	gdfontl.h \
	gdfonts.h \
	io.h \
	gdfontg.h \
	gdfontmb.h \
	gdfontt.h \
	mtables.h
HTMLLIBPODS    = 
HTMLSCRIPTPODS = 
MAN1PODS = 
MAN3PODS = 
HTMLEXT = html
INST_MAN1DIR = ../blib/man1
INSTALLMAN1DIR = $(PREFIX)/share/man/man1
INSTALLSITEMAN1DIR = $(SITEPREFIX)/share/man/man1
INSTALLVENDORMAN1DIR = $(VENDORPREFIX)/share/man/man1
MAN1EXT = 1
INST_MAN3DIR = ../blib/man3
INSTALLMAN3DIR = $(PREFIX)/share/man/man3
INSTALLSITEMAN3DIR = $(SITEPREFIX)/share/man/man3
INSTALLVENDORMAN3DIR = $(VENDORPREFIX)/share/man/man3
MAN3EXT = 3pm
PERM_RW = 644
PERM_RWX = 755

# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc $(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to recall, that
# some make implementations will delete the Makefile when we rebuild it. Because
# we call false(1) when we rebuild it. So make(1) is not completely wrong when it
# does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)/Config.pm $(PERL_INC)/config.h

# Where to put things:
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC  = $(INST_ARCHAUTODIR)/$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)/$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)/$(BASEEXT).bs

EXPORT_LIST = 

PERL_ARCHIVE = 

PERL_ARCHIVE_AFTER = 

TO_INST_PM = 

PM_TO_BLIB = 


# --- MakeMaker tool_autosplit section:

# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e 'use AutoSplit;autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'


# --- MakeMaker tool_xsubpp section:

XSUBPPDIR = /usr/lib/perl5/5.6.1/ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)/typemap $(XSUBPP)
XSUBPPARGS = -typemap $(XSUBPPDIR)/typemap


# --- MakeMaker tools_other section:

SHELL = /bin/sh
CHMOD = chmod
CP = cp
LD = gcc
MV = mv
NOOP = $(SHELL) -c true
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1

# The following is a portable way to say mkdir -p
# To see which directories are created, change the if 0 to if 1
MKPATH = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e mkpath

# This helps us to minimize the effect of the .exists files A yet
# better solution would be to have a stable file in the perl
# distribution with a timestamp of zero. But this solution doesn't
# need any changes to the core distribution and works with older perls
EQUALIZE_TIMESTAMP = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e eqtime


# --- MakeMaker dist section skipped.

# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:

CCFLAGS = -fno-strict-aliasing -I/usr/local/include
OPTIMIZE = -O2 -march=i386 -mcpu=i686
PERLTYPE = 
MPOLLUTE = 


# --- MakeMaker const_loadlibs section:

# libgd might depend on some other libraries:
# See ExtUtils::Liblist for details
#
LD_RUN_PATH = 


# --- MakeMaker const_cccmd section:
CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \
	$(XS_DEFINE_VERSION)

# --- MakeMaker post_constants section:
INST_STATIC = libgd$(LIB_EXT)


# --- MakeMaker pasthru section:

PASTHRU = LIB="$(LIB)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"


# --- MakeMaker c_o section:

.c$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c

.C$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.C

.cpp$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cpp

.cxx$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cxx

.cc$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.cc


# --- MakeMaker xs_c section:

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c


# --- MakeMaker xs_o section:

.xs$(OBJ_EXT):
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c


# --- MakeMaker top_targets section:
all    ::    static

static ::    libgd$(LIB_EXT)

config ::

test :	



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	@$(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section skipped.

# --- MakeMaker dynamic_bs section:

BOOTSTRAP = libgd.bs

# As Mkbootstrap might not write a file (if none is required)
# we use touch to prevent make continually trying to remake it.
# The DynaLoader only reads a non-empty file.
$(BOOTSTRAP): Makefile  $(INST_ARCHAUTODIR)/.exists
	@echo "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" \
		-MExtUtils::Mkbootstrap \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	@$(TOUCH) $(BOOTSTRAP)
	$(CHMOD) $(PERM_RW) $@

$(INST_BOOT): $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists
	@rm -rf $(INST_BOOT)
	-cp $(BOOTSTRAP) $(INST_BOOT)
	$(CHMOD) $(PERM_RW) $@


# --- MakeMaker dynamic_lib section:

# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
ARMAYBE = :
OTHERLDFLAGS = 
INST_DYNAMIC_DEP = 

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)/.exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(PERL_ARCHIVE_AFTER) $(INST_DYNAMIC_DEP)
	$(RM_F) $@
	LD_RUN_PATH="$(LD_RUN_PATH)" $(LD)  $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) -o $@ $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST)
	$(CHMOD) $(PERM_RWX) $@

$(INST_ARCHAUTODIR)/.exists :: /usr/lib/perl5/5.6.1/i386-linux/CORE/perl.h
	@$(MKPATH) $(INST_ARCHAUTODIR)
	@$(EQUALIZE_TIMESTAMP) /usr/lib/perl5/5.6.1/i386-linux/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-@$(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
#static :: Makefile $(INST_STATIC) $(INST_PM)
static :: Makefile $(INST_STATIC)
	@$(NOOP)


# --- MakeMaker static_lib section:

$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)/.exists
	$(RM_RF) $@
	$(FULL_AR) $(AR_STATIC_ARGS) $@ $(OBJECT) && $(RANLIB) $@
	$(CHMOD) $(PERM_RWX) $@
	@echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld



# --- MakeMaker htmlifypods section:

htmlifypods : pure_all
	@$(NOOP)


# --- MakeMaker manifypods section:

manifypods : pure_all
	@$(NOOP)


# --- MakeMaker processPL section:


# --- MakeMaker installbin section:


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean section:
# FILES, libgd$(LIB_EXT)

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	-rm -rf libgd$(LIB_EXT) ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all perlmain.c mon.out core core.*perl.*.? *perl.core so_locations pm_to_blib *$(OBJ_EXT) *$(LIB_EXT) perl.exe $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def $(BASEEXT).exp
	-mv Makefile Makefile.old $(DEV_NULL)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -rf $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	rm -f $(INST_DYNAMIC) $(INST_BOOT)
	rm -f $(INST_STATIC)
	rm -rf Makefile Makefile.old


# --- MakeMaker dist_basics section skipped.

# --- MakeMaker dist_core section skipped.

# --- MakeMaker dist_dir section skipped.

# --- MakeMaker dist_test section skipped.

# --- MakeMaker dist_ci section skipped.

# --- MakeMaker install section skipped.

# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	@$(NOOP)


# --- MakeMaker perldepend section:

PERL_HDRS = \
	$(PERL_INC)/EXTERN.h		\
	$(PERL_INC)/INTERN.h		\
	$(PERL_INC)/XSUB.h		\
	$(PERL_INC)/av.h		\
	$(PERL_INC)/cc_runtime.h	\
	$(PERL_INC)/config.h		\
	$(PERL_INC)/cop.h		\
	$(PERL_INC)/cv.h		\
	$(PERL_INC)/dosish.h		\
	$(PERL_INC)/embed.h		\
	$(PERL_INC)/embedvar.h		\
	$(PERL_INC)/fakethr.h		\
	$(PERL_INC)/form.h		\
	$(PERL_INC)/gv.h		\
	$(PERL_INC)/handy.h		\
	$(PERL_INC)/hv.h		\
	$(PERL_INC)/intrpvar.h		\
	$(PERL_INC)/iperlsys.h		\
	$(PERL_INC)/keywords.h		\
	$(PERL_INC)/mg.h		\
	$(PERL_INC)/nostdio.h		\
	$(PERL_INC)/objXSUB.h		\
	$(PERL_INC)/op.h		\
	$(PERL_INC)/opcode.h		\
	$(PERL_INC)/opnames.h		\
	$(PERL_INC)/patchlevel.h	\
	$(PERL_INC)/perl.h		\
	$(PERL_INC)/perlapi.h		\
	$(PERL_INC)/perlio.h		\
	$(PERL_INC)/perlsdio.h		\
	$(PERL_INC)/perlsfio.h		\
	$(PERL_INC)/perlvars.h		\
	$(PERL_INC)/perly.h		\
	$(PERL_INC)/pp.h		\
	$(PERL_INC)/pp_proto.h		\
	$(PERL_INC)/proto.h		\
	$(PERL_INC)/regcomp.h		\
	$(PERL_INC)/regexp.h		\
	$(PERL_INC)/regnodes.h		\
	$(PERL_INC)/scope.h		\
	$(PERL_INC)/sv.h		\
	$(PERL_INC)/thrdvar.h		\
	$(PERL_INC)/thread.h		\
	$(PERL_INC)/unixish.h		\
	$(PERL_INC)/utf8.h		\
	$(PERL_INC)/util.h		\
	$(PERL_INC)/warnings.h

$(OBJECT) : $(PERL_HDRS)


# --- MakeMaker makefile section:

$(OBJECT) : $(FIRST_MAKEFILE)

# We take a very conservative approach here, but it\'s worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
Makefile : Makefile.PL $(CONFIGDEP)
	@echo "Makefile out-of-date with respect to $?"
	@echo "Cleaning current config before rebuilding Makefile..."
	-@$(RM_F) Makefile.old
	-@$(MV) Makefile Makefile.old
	-$(MAKE) -f Makefile.old clean $(DEV_NULL) || $(NOOP)
	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" Makefile.PL "LIB=/fiery/u6/jstuart/develop/perl/xlib"
	@echo "==> Your Makefile has been rebuilt. <=="
	@echo "==> Please rerun the make command.  <=="
	false

# To change behavior to :: would be nice, but would break Tk b9.02
# so you find such a warning below the dist target.
#Makefile :: $(VERSION_FROM)
#	@echo "Warning: Makefile possibly out of date with $(VERSION_FROM)"


# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = ../perl
FULLPERL      = /usr/bin/perl


# --- MakeMaker test section skipped.

# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"libgd\" VERSION=\"0,10,0,0\">\n}. qq{\t<TITLE>libgd</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"i386-linux\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > libgd.ppd

# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	@$(PERL) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)" \
	"-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Install \
        -e "pm_to_blib({qw{$(PM_TO_BLIB)}},'$(INST_LIB)/auto','$(PM_FILTER)')"
	@$(TOUCH) $@


# --- MakeMaker selfdocument section:

# Full list of MakeMaker attribute values:
#	AR => q[ar]
#	AR_STATIC_ARGS => q[cr]
#	BASEEXT => q[libgd]
#	BOOTDEP => q[]
#	C => [q[gdfontg.c], q[gdfontmb.c], q[gdfontt.c], q[gdfontl.c], q[gdfonts.c], q[libgd.c]]
#	CC => q[gcc]
#	CCCDLFLAGS => q[-fPIC]
#	CCDLFLAGS => q[-rdynamic]
#	CCFLAGS => q[-fno-strict-aliasing -I/usr/local/include]
#	CFLAGS => q[ CCFLAGS = -fno-strict-aliasing -I/usr/local/include OPTIMIZE = -O2 -march=i386 -mcpu=i686 PERLTYPE =  MPOLLUTE =  ]
#	CHMOD => q[chmod]
#	CONFIG => [q[ar], q[cc], q[cccdlflags], q[ccdlflags], q[dlext], q[dlsrc], q[ld], q[lddlflags], q[ldflags], q[libc], q[lib_ext], q[obj_ext], q[osname], q[osvers], q[ranlib], q[sitelibexp], q[sitearchexp], q[so], q[exe_ext], q[full_ar]]
#	CONST_CCCMD => q[CCCMD = $(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) \ 	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \ 	$(XS_DEFINE_VERSION)]
#	CP => q[cp]
#	DEV_NULL => q[> /dev/null 2>&1]
#	DIR => []
#	DIR_TARGET => { PACK002=HASH(...)=>{ $(INST_ARCHAUTODIR)=>q[2] } }
#	DISTNAME => q[libgd]
#	DLBASE => q[$(BASEEXT)]
#	DLEXT => q[so]
#	DLSRC => q[dl_dlopen.xs]
#	EXE_EXT => q[]
#	FIRST_MAKEFILE => q[Makefile]
#	FULLEXT => q[libgd]
#	FULLPERL => q[/usr/bin/perl]
#	FULL_AR => q[/usr/bin/ar]
#	H => [q[gd.h], q[gdfontl.h], q[gdfonts.h], q[io.h], q[gdfontg.h], q[gdfontmb.h], q[gdfontt.h], q[mtables.h]]
#	HAS_LINK_CODE => q[1]
#	HTMLEXT => q[html]
#	HTMLLIBPODS => {  }
#	HTMLSCRIPTPODS => {  }
#	INSTALLARCHLIB => q[$(PREFIX)/lib/perl5/5.6.1/i386-linux]
#	INSTALLBIN => q[$(PREFIX)/bin]
#	INSTALLDIRS => q[site]
#	INSTALLHTMLPRIVLIBDIR => undef
#	INSTALLHTMLSCRIPTDIR => undef
#	INSTALLHTMLSITELIBDIR => undef
#	INSTALLMAN1DIR => q[$(PREFIX)/share/man/man1]
#	INSTALLMAN3DIR => q[$(PREFIX)/share/man/man3]
#	INSTALLPRIVLIB => q[$(PREFIX)/lib/perl5/5.6.1]
#	INSTALLSCRIPT => q[$(PREFIX)/bin]
#	INSTALLSITEARCH => q[$(SITEPREFIX)/lib/perl5/site_perl/5.6.1/i386-linux]
#	INSTALLSITEBIN => q[$(SITEPREFIX)/bin]
#	INSTALLSITELIB => q[$(SITEPREFIX)/lib/perl5/site_perl/5.6.1]
#	INSTALLSITEMAN1DIR => q[$(SITEPREFIX)/share/man/man1]
#	INSTALLSITEMAN3DIR => q[$(SITEPREFIX)/share/man/man3]
#	INSTALLSITESCRIPT => undef
#	INSTALLVENDORARCH => q[$(VENDORPREFIX)/lib/perl5/vendor_perl/5.6.1/i386-linux]
#	INSTALLVENDORBIN => q[$(VENDORPREFIX)/bin]
#	INSTALLVENDORLIB => q[$(VENDORPREFIX)/lib/perl5/vendor_perl/5.6.1]
#	INSTALLVENDORMAN1DIR => q[$(VENDORPREFIX)/share/man/man1]
#	INSTALLVENDORMAN3DIR => q[$(VENDORPREFIX)/share/man/man3]
#	INSTALLVENDORSCRIPT => undef
#	INST_ARCHAUTODIR => q[$(INST_ARCHLIB)/auto/$(FULLEXT)]
#	INST_ARCHLIB => q[../blib/arch]
#	INST_ARCHLIBDIR => q[$(INST_ARCHLIB)]
#	INST_AUTODIR => q[$(INST_LIB)/auto/$(FULLEXT)]
#	INST_BIN => q[../blib/bin]
#	INST_EXE => q[../blib/script]
#	INST_HTMLLIBDIR => undef
#	INST_HTMLSCRIPTDIR => undef
#	INST_LIB => q[../blib/lib]
#	INST_LIBDIR => q[$(INST_LIB)]
#	INST_MAN1DIR => q[../blib/man1]
#	INST_MAN3DIR => q[../blib/man3]
#	INST_SCRIPT => q[../blib/script]
#	LD => q[gcc]
#	LDDLFLAGS => q[-shared -L/usr/local/lib]
#	LDFLAGS => q[ -L/usr/local/lib]
#	LDFROM => q[$(OBJECT)]
#	LD_RUN_PATH => q[]
#	LIBC => q[/lib/libc-2.2.5.so]
#	LIBPERL_A => q[libperl.a]
#	LIBS => [q[]]
#	LIB_EXT => q[.a]
#	LINKTYPE => q[static]
#	MAKEFILE => q[Makefile]
#	MAKE_APERL_FILE => q[Makefile.aperl]
#	MAN1EXT => q[1]
#	MAN1PODS => {  }
#	MAN3EXT => q[3pm]
#	MAN3PODS => {  }
#	MAP_TARGET => q[../perl]
#	MV => q[mv]
#	NAME => q[libgd]
#	NAME_SYM => q[libgd]
#	NEEDS_LINKING => q[1]
#	NOECHO => q[@]
#	NOOP => q[$(SHELL) -c true]
#	OBJECT => q[$(O_FILES)]
#	OBJ_EXT => q[.o]
#	OPTIMIZE => q[-O2 -march=i386 -mcpu=i686]
#	OSNAME => q[linux]
#	OSVERS => q[2.4.17-0.13smp]
#	O_FILES => [q[gdfontg.o], q[gdfontmb.o], q[gdfontt.o], q[gdfontl.o], q[gdfonts.o], q[libgd.o]]
#	PARENT => PACK001=HASH(...)
#	PARENT_NAME => undef
#	PERL => q[/usr/bin/perl]
#	PERLMAINCC => q[$(CC)]
#	PERLTYPE => undef
#	PERL_ARCHLIB => q[/usr/lib/perl5/5.6.1/i386-linux]
#	PERL_INC => q[/usr/lib/perl5/5.6.1/i386-linux/CORE]
#	PERL_LIB => q[/usr/lib/perl5/5.6.1]
#	PERL_SRC => undef
#	PL_FILES => {  }
#	PM => {  }
#	PMLIBDIRS => []
#	PREFIX => q[/usr]
#	PREREQ_PM => {  }
#	RANLIB => q[:]
#	RM_F => q[rm -f]
#	RM_RF => q[rm -rf]
#	SITEARCHEXP => q[/usr/lib/perl5/site_perl/5.6.1/i386-linux]
#	SITELIBEXP => q[/usr/lib/perl5/site_perl/5.6.1]
#	SITEPREFIX => q[$(PREFIX)]
#	SKIPHASH => { install=>q[1], dist=>q[1], dist_ci=>q[1], dist_test=>q[1], dist_dir=>q[1], dist_core=>q[1], dist_basics=>q[1], test=>q[1], dynamic=>q[1] }
#	SO => q[so]
#	TEST_F => q[test -f]
#	TOUCH => q[touch]
#	UMASK_NULL => q[umask 0]
#	VENDORPREFIX => q[$(PREFIX)]
#	VERSION => q[0.10]
#	VERSION_SYM => q[0_10]
#	XS => {  }
#	XSPROTOARG => q[]
#	XS_VERSION => q[0.10]
#	clean => { FILES=>q[libgd$(LIB_EXT)] }

# --- MakeMaker postamble section:


# End.
