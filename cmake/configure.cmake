################################################################################
# Project:  Lib GSL
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2017, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

include(CheckLibraryExists)
include(CheckCSourceCompiles)
include(CheckIncludeFiles)
include(CheckCSourceRuns)
include(CheckSymbolExists)

check_library_exists(m cos "" HAVE_LIBM)
if (HAVE_LIBM)
  set(CMAKE_REQUIRED_LIBRARIES m)
endif ()

# Check for inline.
foreach (keyword inline __inline__ __inline)
  check_c_source_compiles("
    static ${keyword} void foo() { return 0; }
    int main() {}" C_HAS_${keyword})
  if (C_HAS_${keyword})
    set(C_INLINE ${keyword})
    break ()
  endif ()
endforeach ()

if (C_INLINE)
  # Check for GNU-style extern inline.
  check_c_source_compiles("
    extern ${C_INLINE} double foo(double x);
    extern ${C_INLINE} double foo(double x) { return x + 1.0; }
    double foo(double x) { return x + 1.0; }
    int main() { foo(1.0); }" C_EXTERN_INLINE)
  if (C_EXTERN_INLINE)
    set(HAVE_INLINE 1)
  else ()
    # Check for C99-style inline.
    check_c_source_compiles("
      extern inline void* foo() { foo(); return &foo; }
      int main() { return foo() != 0; }" C_C99INLINE)
    if (C_C99INLINE)
      set(HAVE_INLINE 1)
      set(HAVE_C99_INLINE 1)
    endif ()
  endif ()
endif ()
if (C_INLINE AND NOT C_HAS_inline)
  set(inline ${C_INLINE})
endif ()

# Checks for header files.
foreach (header ieeefp.h dlfcn.h inttypes.h memory.h stdint.h stdlib.h
                strings.h string.h sys/stat.h sys/types.h unistd.h)
  string(TOUPPER HAVE_${header} var)
  string(REGEX REPLACE "\\.|/" "_" var ${var})
  check_include_files(${header} ${var})
endforeach ()

check_include_files(stdio.h STDC_HEADERS)

if(NOT HAVE_SYS_TYPES_H)
    set(size_t "unsigned int")
endif()

# Check for IEEE arithmetic interface type.
if (CMAKE_SYSTEM_NAME MATCHES Linux)
  if (CMAKE_SYSTEM_PROCESSOR MATCHES sparc)
    set(HAVE_GNUSPARC_IEEE_INTERFACE 1)
  elseif (CMAKE_SYSTEM_PROCESSOR MATCHES powerpc)
    set(HAVE_GNUPPC_IEEE_INTERFACE 1)
  elseif (CMAKE_SYSTEM_PROCESSOR MATCHES 86)
    set(HAVE_GNUX86_IEEE_INTERFACE 1)
  endif ()
elseif (CMAKE_SYSTEM_NAME MATCHES SunOS)
  set(HAVE_SUNOS4_IEEE_INTERFACE 1)
elseif (CMAKE_SYSTEM_NAME MATCHES Solaris)
  set(HAVE_SOLARIS_IEEE_INTERFACE 1)
elseif (CMAKE_SYSTEM_NAME MATCHES hpux)
  set(HAVE_HPUX_IEEE_INTERFACE 1)
elseif (CMAKE_SYSTEM_NAME MATCHES Darwin)
  if (CMAKE_SYSTEM_PROCESSOR MATCHES powerpc)
    set(HAVE_DARWIN_IEEE_INTERFACE 1)
  elseif (CMAKE_SYSTEM_PROCESSOR MATCHES 86)
    set(HAVE_DARWIN86_IEEE_INTERFACE 1)
  endif ()
elseif (CMAKE_SYSTEM_NAME MATCHES NetBSD)
  set(HAVE_NETBSD_IEEE_INTERFACE 1)
elseif (CMAKE_SYSTEM_NAME MATCHES OpenBSD)
  set(HAVE_OPENBSD_IEEE_INTERFACE 1)
elseif (CMAKE_SYSTEM_NAME MATCHES FreeBSD)
  set(HAVE_FREEBSD_IEEE_INTERFACE 1)
endif ()

# Check for FPU_SETCW.
if (HAVE_GNUX86_IEEE_INTERFACE)
  check_c_source_compiles("
    #include <fpu_control.h>
    #ifndef _FPU_SETCW
    #include <i386/fpu_control.h>
    #define _FPU_SETCW(cw) __setfpucw(cw)
    #endif
    int main() { unsigned short mode = 0 ; _FPU_SETCW(mode); }"
    HAVE_FPU_SETCW)
  if (NOT HAVE_FPU_SETCW)
    set(HAVE_GNUX86_IEEE_INTERFACE 0)
  endif ()
endif ()

# Check for SSE extensions.
if (HAVE_GNUX86_IEEE_INTERFACE)
  check_c_source_compiles("
    #include <stdlib.h>
    #define _FPU_SETMXCSR(cw) asm volatile (\"ldmxcsr %0\" : : \"m\" (*&cw))
    int main() { unsigned int mode = 0x1f80 ; _FPU_SETMXCSR(mode); exit(0); }"
    HAVE_FPU_X86_SSE)
endif ()

# Check IEEE comparisons, whether "x != x" is true for NaNs.
check_c_source_runs("
    #include <math.h>
    int main (void)
    {
        int status; double inf, nan;
        inf = exp(1.0e10);
        nan = inf / inf ;
        status = (nan == nan);
        exit (status);
    }" HAVE_IEEE_COMPARISONS)

# Check for IEEE denormalized arithmetic.
check_c_source_runs("
    #include <math.h>
    int main (void)
    {
       int i, status;
       volatile double z = 1e-308;
       for (i = 0; i < 5; i++) { z = z / 10.0 ; };
       for (i = 0; i < 5; i++) { z = z * 10.0 ; };
       status = (z == 0.0);
       exit (status);
    }" HAVE_IEEE_DENORMALS)

# Check for long double stdio.
check_c_source_runs("
#include <stdlib.h>
#include <stdio.h>
int main (void)
{
  const char * s = \"5678.25\"; long double x = 1.234 ;
  fprintf(stderr,\"%Lg\n\",x) ;
  sscanf(s, \"%Lg\", &x);
  if (x == 5678.25) {exit (0);} else {exit(1); }
}" HAVE_PRINTF_LONGDOUBLE)

if (NOT CMAKE_COMPILER_IS_GNUCC)
check_c_source_runs("
  #include <limits.h>
  int main (void) { return CHAR_MIN == 0 ? EXIT_SUCCESS : EXIT_FAILURE; }" __CHAR_UNSIGNED__)
endif ()

# Remember to put a definition in config.h.in for each of these.
check_symbol_exists(EXIT_SUCCESS stdlib.h HAVE_EXIT_SUCCESS)
check_symbol_exists(EXIT_FAILURE stdlib.h HAVE_EXIT_FAILURE)
if (HAVE_EXIT_SUCCESS AND HAVE_EXIT_FAILURE)
    set(HAVE_EXIT_SUCCESS_AND_FAILURE 1)
endif ()

set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE=1")
check_symbol_exists(feenableexcept fenv.h HAVE_DECL_FEENABLEEXCEPT)
check_symbol_exists(fesettrapenable fenv.h HAVE_DECL_FESETTRAPENABLE)
set(CMAKE_REQUIRED_DEFINITIONS "")
check_symbol_exists(hypot math.h HAVE_DECL_HYPOT)
check_symbol_exists(expm1 math.h HAVE_DECL_EXPM1)
check_symbol_exists(acosh math.h HAVE_DECL_ACOSH)
check_symbol_exists(asinh math.h HAVE_DECL_ASINH)
check_symbol_exists(atanh math.h HAVE_DECL_ATANH)
check_symbol_exists(ldexp math.h HAVE_DECL_LDEXP)
check_symbol_exists(frexp math.h HAVE_DECL_FREXP)
check_symbol_exists(fprnd_t float.h HAVE_DECL_FPRND_T)
check_symbol_exists(isinf math.h HAVE_DECL_ISINF)
check_symbol_exists(isfinite math.h HAVE_DECL_ISFINITE)
if (HAVE_IEEEFP_H)
    set(IEEEFP_H ieeefp.h)
endif ()
check_symbol_exists(finite math.h;${IEEEFP_H} HAVE_DECL_FINITE)
check_symbol_exists(isnan math.h HAVE_DECL_ISNAN)

# OpenBSD has a broken implementation of log1p.
if (CMAKE_SYSTEM_NAME MATCHES OpenBSD)
    message("avoiding OpenBSD system log1p - using gsl version")
else ()
    check_symbol_exists(log1p math.h HAVE_DECL_LOG1P)
endif ()

# Check for extended floating point registers.
if (NOT (CMAKE_SYSTEM_PROCESSOR MATCHES "^(sparc|powerpc|hppa|alpha)"))
    set(HAVE_EXTENDED_PRECISION_REGISTERS 1)
endif ()

check_symbol_exists(memcpy string.h HAVE_MEMCPY)
check_symbol_exists(memmove string.h HAVE_MEMMOVE)
check_symbol_exists(strdup string.h HAVE_STRDUP)
check_symbol_exists(strtol stdlib.h HAVE_STRTOL)
check_symbol_exists(strtoul stdlib.h HAVE_STRTOUL)
check_symbol_exists(vprintf stdio.h HAVE_VPRINTF)

if (GSL_DISABLE_WARNINGS)
  # Disable additional warnings.
  if (MSVC)
    add_definitions(
      -D_CRT_SECURE_NO_WARNINGS
      /wd4018 /wd4028 /wd4056 /wd4244 /wd4267 /wd4334 /wd4700 /wd4723 /wd4756)
  else ()
    foreach (flag -Wall -Wextra -pedantic)
      string(REPLACE ${flag} "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    endforeach ()
  endif ()
endif ()

option(MSVC_RUNTIME_DYNAMIC "Use dynamically-linked runtime: /MD(d)" OFF)

if (MSVC_RUNTIME_DYNAMIC)
  set(CMAKE_COMPILER_FLAGS_VARIABLES
    CMAKE_C_FLAGS_DEBUG
    CMAKE_C_FLAGS_MINSIZEREL
    CMAKE_C_FLAGS_RELEASE
    CMAKE_C_FLAGS_RELWITHDEBINFO
    CMAKE_CXX_FLAGS_DEBUG
    CMAKE_CXX_FLAGS_MINSIZEREL
    CMAKE_CXX_FLAGS_RELEASE
    CMAKE_CXX_FLAGS_RELWITHDEBINFO
  )
  foreach(variable ${CMAKE_COMPILER_FLAGS_VARIABLES})
    string(REGEX REPLACE "/MT" "/MD" ${variable} "${${variable}}")
  endforeach()
endif ()

set(PACKAGE "gsl")
set(PACKAGE_NAME ${PACKAGE})
set(PACKAGE_STRING "${PACKAGE_NAME} ${VERSION}")
set(PACKAGE_TARNAME ${PACKAGE})
set(PACKAGE_BUGREPORT "https://github.com/nextgis-borsch/lib_gsl/issues")
set(PACKAGE_URL "https://github.com/nextgis-borsch/lib_gsl")
set(PACKAGE_VERSION ${VERSION})
set(RELEASED 1)
set(LT_OBJDIR ".libs/")

if (BUILD_SHARED_LIBS AND WIN32)
    unset(GSL_DISABLE_DEPRECATED)
else()
    set(GSL_DISABLE_DEPRECATED TRUE)
endif()

configure_file(${CMAKE_SOURCE_DIR}/cmake/config.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/config.h IMMEDIATE @ONLY)
add_definitions(-DHAVE_CONFIG_H)

set(GSL_LIBS ${PROJECT_NAME})
if(HAVE_LIBM)
    set(GSL_LIBM m)
endif()

configure_file(${CMAKE_SOURCE_DIR}/cmake/gsl.pc.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/gsl.pc @ONLY)

configure_file(${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)
