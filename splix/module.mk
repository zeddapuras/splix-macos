#
#	module.mk			(C) 2007-2008, Aurélien Croc (AP²C)
#
#  Compilation file for SpliX
#
# Options: DISABLE_JBIG
# 	   DISABLE_THREADS
#          DISABLE_BLACKOPTIM
# Compilation option:
# 	   V=1          Verbose mode
# 	   DESTDIR=xxx  Change the destination directory prefix
# 	   DRV_ONLY     Don't install PPD files at all, only DRV files.

MODE			:= optimized

SUBDIRS 		+= src
TARGETS			:= rastertoqpdl pstoqpdl
PRE_GENERIC_TARGETS	:= optionList


# Default options
THREADS			?= 2
CACHESIZE		?= 30
DISABLE_JBIG		?= 0
DISABLE_THREADS		?= 0
DISABLE_BLACKOPTIM	?= 0
DRV_ONLY		?= 0


# Flags
ifeq ($(ARCHI),Darwin)
# macOS: niente cups.pc; le API raster/PPD stanno in libcups (SDK di sistema).
# jbig85 da Homebrew, linkato staticamente per non dipendere da /opt/homebrew a runtime.
# ARCHFLAGS: es. "-arch arm64 -arch x86_64 -mmacosx-version-min=11.0" per un binario universale.
JBIGDIR			?= /opt/homebrew/opt/jbigkit
ARCHFLAGS		?= -arch arm64
CXXFLAGS		+= $(ARCHFLAGS) `cups-config --cflags` -Iinclude -Wall -I$(JBIGDIR)/include -Wno-deprecated-declarations
LDFLAGS			+= $(ARCHFLAGS)
CUPSLIBS		:= `cups-config --libs`
JBIGLIB			:= $(JBIGDIR)/lib/libjbig85.a
else
CXXFLAGS		+= `pkg-config --cflags cups` -Iinclude -Wall -I/opt/local/include
CUPSLIBS		:= `pkg-config --libs cups` -lcupsimage
JBIGLIB			:= -ljbig85
endif
DEBUG_CXXFLAGS		+= -DDEBUG  -DDUMP_CACHE
OPTIM_CXXFLAGS 		+= -g
rastertoqpdl_LDFLAGS	:= $(LDFLAGS) -L/opt/local/lib
rastertoqpdl_LIBS	:= $(CUPSLIBS)
pstoqpdl_LDFLAGS	:= $(LDFLAGS)
pstoqpdl_LIBS		:= $(CUPSLIBS)


# Update compilation flags with defined options
ifneq ($(DISABLE_THREADS),0)
CXXFLAGS		+= -DDISABLE_THREADS
else
CXXFLAGS		+= -DTHREADS=$(THREADS) -DCACHESIZE=$(CACHESIZE)
rastertoqpdl_LIBS	+= -lpthread
pstoqpdl_LIBS		+= -lpthread
endif
ifneq ($(DISABLE_JBIG),0)
CXXFLAGS		+= -DDISABLE_JBIG
else
rastertoqpdl_LIBS	+= $(JBIGLIB)
endif
ifneq ($(DISABLE_BLACKOPTIM),0)
CXXFLAGS		+= -DDISABLE_BLACKOPTIM
endif


# Get some information
ifeq ($(ARCHI),Darwin)
CUPSFILTER		:= /Library/Printers/SpliX/Filters
CUPSPPD			?= /Library/Printers/PPDs/Contents/Resources
CUPSDRV			?= `cups-config --datadir`/drv
else
CUPSFILTER		:= `pkg-config --variable=cups_serverbin cups`/filter
CUPSPPD			?= `pkg-config --variable=cups_datadir cups`/model
CUPSDRV			?= `pkg-config --variable=cups_datadir cups`/drv
endif
ifeq ($(ARCHI),Darwin)
PSTORASTER		:= pstocupsraster
else
PSTORASTER		:= pstoraster
endif
GSTORASTER		:= gstoraster
CUPSPROFILE			:= `cups-config --datadir`/profiles
export CUPSFILTER CUPSPPD CUPSDRV


# Specific information needed by pstoqpdl
src_pstoqpdl_cpp_FLAGS	:= -DRASTERDIR=\"$(CUPSFILTER)\"
src_pstoqpdl_cpp_FLAGS	+= -DRASTERTOQPDL=\"rastertoqpdl\"
src_pstoqpdl_cpp_FLAGS	+= -DPSTORASTER=\"$(PSTORASTER)\"
src_pstoqpdl_cpp_FLAGS	+= -DGSTORASTER=\"$(GSTORASTER)\"
src_pstoqpdl_cpp_FLAGS	+= -DCUPSPPD=\"$(CUPSPPD)\"
src_pstoqpdl_cpp_FLAGS	+= -DCUPSPROFILE=\"$(CUPSPROFILE)\"

