################################################################################
# Project:  Lib GSL
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2017-2021, NextGIS <info@nextgis.com>
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

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(gsl)

set(LIB_NAME ${PROJECT_NAME})

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()

# Some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# Set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
  set(INSTALL_BIN_DIR "bin" CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)
  set(INSTALL_CMAKECONF_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
  set(SKIP_INSTALL_HEADERS ON)
  set(SKIP_INSTALL_EXECUTABLES ON)
  set(SKIP_INSTALL_FILES ON)
  set(SKIP_INSTALL_EXPORT ON)
  set(CMAKE_MACOSX_RPATH ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_DOC_DIR ${CMAKE_INSTALL_DOCDIR} CACHE INTERNAL "Share directory for data" FORCE)
    set(INSTALL_CMAKECONF_DIR ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
endif()

include(util)
check_version(GSL_MAJOR_VERSION GSL_MINOR_VERSION GSL_VERSION)
set(VERSION ${GSL_VERSION})

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${GSL_MAJOR_VERSION}")
endif()
report_version(${PROJECT_NAME} ${VERSION})

include(configure)

include_directories(${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR})

if (POLICY CMP0054)
  # Only interpret `if` arguments as variables or keywords when unquoted.
  cmake_policy(SET CMP0054 NEW)
endif ()
if (POLICY CMP0053)
  cmake_policy(SET CMP0053 NEW)
endif( )

option(GSL_DISABLE_WARNINGS "disable warnings." ON)

# The following part of config.h is hard to derive from configure.ac.
string(REGEX MATCHALL "[^\n]*\n" CONFIG
"/* Define if you have inline with C99 behavior */
#undef HAVE_C99_INLINE

/* Define to 1 if you have the declaration of `acosh', and to 0 if you don't.
   */
#undef HAVE_DECL_ACOSH

/* Define to 1 if you have the declaration of `asinh', and to 0 if you don't.
   */
#undef HAVE_DECL_ASINH

/* Define to 1 if you have the declaration of `atanh', and to 0 if you don't.
   */
#undef HAVE_DECL_ATANH

/* Define to 1 if you have the declaration of `expm1', and to 0 if you don't.
   */
#undef HAVE_DECL_EXPM1

/* Define to 1 if you have the declaration of `feenableexcept', and to 0 if
   you don't. */
#undef HAVE_DECL_FEENABLEEXCEPT

/* Define to 1 if you have the declaration of `fesettrapenable', and to 0 if
   you don't. */
#undef HAVE_DECL_FESETTRAPENABLE

/* Define to 1 if you have the declaration of `finite', and to 0 if you don't.
   */
#undef HAVE_DECL_FINITE

/* Define to 1 if you have the declaration of `fprnd_t', and to 0 if you
   don't. */
#undef HAVE_DECL_FPRND_T

/* Define to 1 if you have the declaration of `frexp', and to 0 if you don't.
   */
#undef HAVE_DECL_FREXP

/* Define to 1 if you have the declaration of `hypot', and to 0 if you don't.
   */
#undef HAVE_DECL_HYPOT

/* Define to 1 if you have the declaration of `isfinite', and to 0 if you
   don't. */
#undef HAVE_DECL_ISFINITE

/* Define to 1 if you have the declaration of `isinf', and to 0 if you don't.
   */
#undef HAVE_DECL_ISINF

/* Define to 1 if you have the declaration of `isnan', and to 0 if you don't.
   */
#undef HAVE_DECL_ISNAN

/* Define to 1 if you have the declaration of `ldexp', and to 0 if you don't.
   */
#undef HAVE_DECL_LDEXP

/* Define to 1 if you have the declaration of `log1p', and to 0 if you don't.
   */
#undef HAVE_DECL_LOG1P

/* Define to 1 if you have the <dlfcn.h> header file. */
#undef HAVE_DLFCN_H

/* Define to 1 if you don't have `vprintf' but do have `_doprnt.' */
#undef HAVE_DOPRNT

/* Defined if you have ansi EXIT_SUCCESS and EXIT_FAILURE in stdlib.h */
#undef HAVE_EXIT_SUCCESS_AND_FAILURE

/* Defined on architectures with excess floating-point precision */
#undef HAVE_EXTENDED_PRECISION_REGISTERS

/* Define if x86 processor has sse extensions. */
#undef HAVE_FPU_X86_SSE

/* Define to 1 if you have the <ieeefp.h> header file. */
#undef HAVE_IEEEFP_H

/* Define this if IEEE comparisons work correctly (e.g. NaN != NaN) */
#undef HAVE_IEEE_COMPARISONS

/* Define this if IEEE denormalized numbers are available */
#undef HAVE_IEEE_DENORMALS

/* Define if you have inline */
#undef HAVE_INLINE

/* Define to 1 if you have the <inttypes.h> header file. */
#undef HAVE_INTTYPES_H

/* Define to 1 if you have the `m' library (-lm). */
#undef HAVE_LIBM

/* Define to 1 if you have the `memcpy' function. */
#undef HAVE_MEMCPY

/* Define to 1 if you have the `memmove' function. */
#undef HAVE_MEMMOVE

/* Define to 1 if you have the <memory.h> header file. */
#undef HAVE_MEMORY_H

/* Define this if printf can handle %Lf for long double */
#undef HAVE_PRINTF_LONGDOUBLE

/* Define to 1 if you have the <stdint.h> header file. */
#undef HAVE_STDINT_H

/* Define to 1 if you have the <stdlib.h> header file. */
#undef HAVE_STDLIB_H

/* Define to 1 if you have the `strdup' function. */
#undef HAVE_STRDUP

/* Define to 1 if you have the <strings.h> header file. */
#undef HAVE_STRINGS_H

/* Define to 1 if you have the <string.h> header file. */
#undef HAVE_STRING_H

/* Define to 1 if you have the `strtol' function. */
#undef HAVE_STRTOL

/* Define to 1 if you have the `strtoul' function. */
#undef HAVE_STRTOUL

/* Define to 1 if you have the <sys/stat.h> header file. */
#undef HAVE_SYS_STAT_H

/* Define to 1 if you have the <sys/types.h> header file. */
#undef HAVE_SYS_TYPES_H

/* Define to 1 if you have the <unistd.h> header file. */
#undef HAVE_UNISTD_H

/* Define to 1 if you have the `vprintf' function. */
#undef HAVE_VPRINTF

/* Define if you need to hide the static definitions of inline functions */
#undef HIDE_INLINE_STATIC

/* Define to the sub-directory in which libtool stores uninstalled libraries.
   */
#undef LT_OBJDIR

/* Name of package */
#undef PACKAGE

/* Define to the address where bug reports for this package should be sent. */
#undef PACKAGE_BUGREPORT

/* Define to the full name of this package. */
#undef PACKAGE_NAME

/* Define to the full name and version of this package. */
#undef PACKAGE_STRING

/* Define to the one symbol short name of this package. */
#undef PACKAGE_TARNAME

/* Define to the home page for this package. */
#undef PACKAGE_URL

/* Define to the version of this package. */
#undef PACKAGE_VERSION

/* Defined if this is an official release */
#undef RELEASED

/* Define to 1 if you have the ANSI C header files. */
#undef STDC_HEADERS

/* Version number of package */
#undef VERSION

/* Define to 1 if type `char' is unsigned and you are not using gcc.  */
#ifndef __CHAR_UNSIGNED__
# undef __CHAR_UNSIGNED__
#endif

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
#undef inline
#endif

/* Define to `unsigned int' if <sys/types.h> does not define. */
#undef size_t

/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
#undef volatile
")

# Get version numbers and parts of config.h from configure.ac.
file(READ configure.ac LINES)
# Replace semicolons with "<semi>" to avoid CMake messing with them.
string(REPLACE ";" "<semi>" LINES "${LINES}")
# Split into lines keeping newlines to avoid foreach skipping empty ones.
string(REGEX MATCHALL "[^\n]*\n" LINES "${LINES}")
set(ah_command FALSE)
foreach (line "${EXTRA_CONFIG}" ${LINES})
  string(REPLACE ";" "" line "${line}")
  if (ah_command)
    # Do nothing.
  elseif (line MATCHES "AC_INIT[^,]*,\\[(.*)\\].*")
    set(VERSION ${CMAKE_MATCH_1})
    message(STATUS "Got VERSION=${VERSION} from configure.ac")
  elseif (line MATCHES "((GSL|CBLAS)_(CURRENT|REVISION|AGE))=(.*)\n")
    set(${CMAKE_MATCH_1} ${CMAKE_MATCH_4})
    message(STATUS "Got ${CMAKE_MATCH_1}=${CMAKE_MATCH_4} from configure.ac")
  elseif (line MATCHES "AH_BOTTOM\\(\\[(.*)")
    set(ah_command bottom)
    set(line "${CMAKE_MATCH_1}")
  elseif (line MATCHES "AH_VERBATIM[^,]+,(.*)")
    set(ah_command verbatim)
    set(line "${CMAKE_MATCH_1}")
  endif ()
  if (ah_command)
    set(saved_ah_command ${ah_command})
    if (line MATCHES "^\\[(.*)")
      set(line "${CMAKE_MATCH_1}")
    endif ()
    if (line MATCHES "\\]\\)")
      set(ah_command FALSE)
      string(REPLACE "])" "" line "${line}")
    endif ()
    # For some reason CMake may bundle several lines together. Split them too.
    string(REGEX MATCHALL "[^\n]*\n" sublines "${line}")
    set(config_add "")
    foreach (subline ${sublines})
      set(config_add ${config_add} "${subline}")
    endforeach ()
    if (saved_ah_command STREQUAL "verbatim")
      set(CONFIG ${config_add} ${CONFIG})
    else ()
      set(CONFIG ${CONFIG} "\n" ${config_add})
    endif ()
  endif ()
endforeach ()
set(PACKAGE_VERSION ${VERSION})
set(PACKAGE_STRING "${PACKAGE} ${VERSION}")

if (NOT (VERSION MATCHES "\\+"))
  # Defined if this is an official release.
  set(RELEASED /**/)
endif ()

include(CheckLibraryExists)
check_library_exists(m cos "" HAVE_LIBM)
if (HAVE_LIBM)
  set(CMAKE_REQUIRED_LIBRARIES m)
endif ()

include(CheckCSourceCompiles)

# Check for inline. (also check for __forceinline?)
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
include(CheckIncludeFiles)
foreach (header ieeefp.h dlfcn.h inttypes.h memory.h stdint.h stdlib.h
                strings.h string.h sys/stat.h sys/types.h unistd.h)
  string(TOUPPER HAVE_${header} var)
  string(REGEX REPLACE "\\.|/" "_" var ${var})
  check_include_files(${header} ${var})
endforeach ()
check_include_files(stdio.h STDC_HEADERS)

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

# Compiles the source code, runs the program and sets ${VAR} to 1 if the
# return value is equal to ${RESULT}.
macro(check_run_result SRC RESULT VAR)
  set(SRC_FILE ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.c)
  file(WRITE ${SRC_FILE} "${SRC}")
  try_run(RUN_RESULT COMPILE_RESULT ${CMAKE_BINARY_DIR} ${SRC_FILE}
          CMAKE_FLAGS -DLINK_LIBRARIES:STRING=${CMAKE_REQUIRED_LIBRARIES})
  if (RUN_RESULT EQUAL ${RESULT})
    set(${VAR} 1)
  endif ()
endmacro()

# Check IEEE comparisons, whether "x != x" is true for NaNs.
check_run_result("
  #include <math.h>
  int main (void)
  {
     int status; double inf, nan;
     inf = exp(1.0e10);
     nan = inf / inf ;
     status = (nan == nan);
     exit (status);
  }" 0 HAVE_IEEE_COMPARISONS)

# Check for IEEE denormalized arithmetic.
check_run_result("
  #include <math.h>
  int main (void)
  {
     int i, status;
     volatile double z = 1e-308;
     for (i = 0; i < 5; i++) { z = z / 10.0 ; };
     for (i = 0; i < 5; i++) { z = z * 10.0 ; };
     status = (z == 0.0);
     exit (status);
  }" 0 HAVE_IEEE_DENORMALS)

# Check for long double stdio.
check_run_result("
  #include <stdlib.h>
  #include <stdio.h>
  int main (void)
  {
    const char * s = \"5678.25\"; long double x = 1.234 ;
    fprintf(stderr,\"%Lg\n\",x) ;
    sscanf(s, \"%Lg\", &x);
    if (x == 5678.25) {exit (0);} else {exit(1); }
  }" 0 HAVE_PRINTF_LONGDOUBLE)

if (NOT CMAKE_COMPILER_IS_GNUCC)
  check_run_result("
    #include <limits.h>
    int main (void) { return CHAR_MIN == 0; }" 1 __CHAR_UNSIGNED__)
endif ()

# Remember to put a definition in config.h.in for each of these.
include(CheckSymbolExists)
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

# Process config.h using autoconf rules.
#file(STRINGS ${GSL_SOURCE_DIR}/config.h.in CONFIG)
list(LENGTH CONFIG length)
math(EXPR length "${length} - 1")
foreach (i RANGE ${length})
  list(GET CONFIG ${i} line)
  if (line MATCHES "^#( *)undef (.*)\n")
    set(space "${CMAKE_MATCH_1}")
    set(var ${CMAKE_MATCH_2})
    if (NOT DEFINED ${var} OR (var MATCHES "HAVE_.*_H" AND NOT ${var}))
      set(line "/* #${space}undef ${var} */\n")
    else ()
      if ("${${var}}" STREQUAL "/**/" OR "${var}" STREQUAL "inline")
        set(value ${${var}})
      elseif (NOT (var MATCHES ^HAVE OR ${var} EQUAL 0 OR ${var} EQUAL 1))
        set(value \"${${var}}\")
      elseif (${var})
        set(value 1)
      else ()
        set(value 0)
      endif ()
      set(line "#${space}define ${var} ${value}\n")
    endif ()
  elseif (BUILD_SHARED_LIBS AND WIN32 AND line MATCHES "^#define GSL_DISABLE_DEPRECATED .*")
    # Keep deprecated symbols when compiling a Windows DLL to prevent linkage errors.
    set(line "/* #undef GSL_DISABLE_DEPRECATED */\n")
  endif ()
  string(REPLACE "<semi>" ";" line "${line}")
  set(CONFIG_OUT "${CONFIG_OUT}${line}")
endforeach ()
# file(WRITE ${GSL_BINARY_DIR}/config.h
# "/* config.h.  Generated from config.h.in by configure.  */
# /* config.h.in.  Generated from configure.ac by autoheader.  */

# ${CONFIG_OUT}")
configure_file(config.h.cmake.in ${${PROJECT_NAME}_BINARY_DIR}/config.h)

add_definitions(-DHAVE_CONFIG_H)

if (GSL_DISABLE_WARNINGS)
  # Disable additional warnings.
  if (MSVC)
    add_definitions(
      -D_CRT_SECURE_NO_WARNINGS
      /wd4018 /wd4028 /wd4056 /wd4101 /wd4244 /wd4267 /wd4334 /wd4477 /wd4700 /wd4723 /wd4756 /wd4996)
  else ()
    foreach (flag -Wall -Wextra -pedantic)
      string(REPLACE ${flag} "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    endforeach ()
  endif ()
endif ()

# Append compiler flags provided via environment variables.
# E.g.: C_FLAGS="-Werror" cmake -G "Unix Makefiles" ../gsl
foreach( lang C CXX )
  if( DEFINED ENV{${lang}_FLAGS} )
    string( APPEND CMAKE_${lang}_FLAGS " $ENV{${lang}_FLAGS}" )
    message( STATUS "CMAKE_${lang}_FLAGS = ${CMAKE_${lang}_FLAGS}" )
    # set( CMAKE_${lang}_FLAGS ${CMAKE_${lang}_FLAGS} CACHE STRING "Compiler flags" FORCE )
  endif()
endforeach()

enable_testing()

# Adds a GSL test. Usage:
#   add_gsl_test(<exename> <source> ...)
function(add_gsl_test exename)
  if (GSL_DISABLE_TESTS)
    return()
  endif ()
  add_executable(${exename} ${ARGN})
  target_link_libraries(${exename} ${LIB_NAME})
  target_include_directories(${exename} PRIVATE .)
  add_test(${exename} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${exename})
endfunction()

file(GLOB GSL_HEADER_PATHS_NE "${${PROJECT_NAME}_SOURCE_DIR}/gsl*.h")
file(GLOB dirs "${${PROJECT_NAME}_SOURCE_DIR}/*")
foreach (dir ${dirs})
  if (NOT (dir MATCHES "gsl$"))
    file(GLOB headers "${dir}/gsl*.h")
    set(GSL_HEADER_PATHS_NE ${GSL_HEADER_PATHS_NE} ${headers})
  endif ()
endforeach()
set(GSL_HEADER_PATHS "")
foreach (path ${GSL_HEADER_PATHS_NE})
  get_filename_component(name ${path} NAME)
  set(GSL_HEADERS ${GSL_HEADERS} gsl/${name})
  string(REPLACE "\ " "\\ " escaped ${path})
  set(GSL_HEADER_PATHS ${GSL_HEADER_PATHS} ${escaped}) 
endforeach ()

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/copy-headers.cmake "
  file(MAKE_DIRECTORY gsl)
  foreach (path ${GSL_HEADER_PATHS})
    get_filename_component(filename \${path} NAME)
    configure_file(\${path} \"${${PROJECT_NAME}_BINARY_DIR}/gsl/\${filename}\" COPYONLY)
  endforeach ()")

add_custom_command(OUTPUT ${GSL_HEADERS}
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/copy-headers.cmake)
add_custom_target(copy-headers DEPENDS ${GSL_HEADERS})

macro(get_sources dir line source_var)
  set(${source_var})
  string(REGEX REPLACE ".*_SOURCES[ \t]*=(.*)" "\\1" sources ${line})
  string(REGEX MATCHALL "[^ \t]+" sources ${sources})
  foreach (src ${sources})
    set(${source_var} ${${source_var}} ${dir}/${src})
  endforeach ()
endmacro()

# Get subdirectories from Makefile.am.
file(STRINGS Makefile.am lines REGEX "^SUBDIRS[ \t]*=")
foreach (line ${lines})
  string(REGEX REPLACE "SUBDIRS[ \t]*=(.*)" "\\1" dirs ${line})
  string(REGEX MATCHALL "[^ ]+" dirs ${dirs})
endforeach ()


## Experimental: define dependencies
## Only activated if BUILDLIB is defined
if(DEFINED BUILDLIBS)
    set(err_DEP .)

    set(bst_DEP err)
    set(block_DEP err)
    set(cheb_DEP err)
    set(combination_DEP err)
    set(ieee-utils_DEP err)
    set(poly_DEP err)
    set(sort_DEP err)
    set(histogram_DEP block)

    set(fft_DEP cblas err)
    set(blas_DEP cblas err)
    set(vector_DEP block blas)

    set(statistics_DEP vector sort)
    set(rstat_DEP statistics)
    set(movstat_DEP rstat)

    set(ntuple_DEP histogram)

    set(matrix_DEP vector)

    set(filter_DEP vector movstat)
    set(permutation_DEP matrix)
    set(wavelet_DEP matrix)
    set(specfunc_DEP matrix complex eigen)

    set(dht_DEP specfunc)
    set(integration_DEP specfunc)
    set(multimin_DEP matrix poly)
    set(spmatrix_DEP bst matrix)
    set(linalg_DEP permutation complex sys)

    set(interpolation_DEP linalg poly)
    set(eigen_DEP linalg)
    set(bspline_DEP linalg statistics)
    set(multifit_nlinear_DEP linalg poly)
    set(multifit_DEP linalg min statistics)
    set(multiroots_DEP linalg)
    set(ode-initval_DEP linalg)
    set(ode-initval2_DEP linalg)

    set(multilarge_nlinear_DEP multifit poly)
    set(multilarge_DEP multifit eigen)

    set(spblas_DEP spmatrix)
    set(splinalg_DEP spblas eigen)

    set(randist_DEP linalg specfunc statistics integration)

    set(cdf_DEP specfunc randist)

    set(bst_test_DEP sort)
    set(sort_test_DEP permutation)
    set(eigen_test_DEP sort)
    set(multifit_test_DEP specfunc)
    set(poly_test_DEP sort)
    set(randist_test_DEP cdf)
    set(rstat_test_DEP randist cdf)


    set_property(GLOBAL PROPERTY HAVETOBUILD_GLOBAL "")
    set_property(GLOBAL PROPERTY ADDEDLIBS_GLOBAL "")

    set(HAVETOBUILD "")
    set(ALREADYADDED "")
    function(addDependencies lib)
        get_property(ALREADYADDED GLOBAL PROPERTY ADDEDLIBS_GLOBAL)
        get_property(HAVETOBUILD GLOBAL PROPERTY HAVETOBUILD_GLOBAL)
        if(NOT ${lib} IN_LIST ALREADYADDED)
          set(ALREADYADDED ${ALREADYADDED} ${lib})
          set_property(GLOBAL PROPERTY ADDEDLIBS_GLOBAL ${ALREADYADDED})
        else()
          return()
        endif()

       if(NOT ${lib} IN_LIST HAVETOBUILD)
          set(HAVETOBUILD ${HAVETOBUILD} ${lib})
          set_property(GLOBAL PROPERTY HAVETOBUILD_GLOBAL ${HAVETOBUILD})
        endif()
         foreach(dep ${${lib}_DEP})
           addDependencies(${dep})
         endforeach()
       if(NOT GSL_DISABLE_TESTS)
         foreach(dep ${${lib}_test_DEP})
           addDependencies(${dep})
         endforeach()
       endif()
    endfunction()

    message(STATUS "Building only a subset of GSL")
    message(STATUS "Specified libraries: ${BUILDLIBS}")

    # Add test dependencies to the list if needed
    if(NOT GSL_DISABLE_TESTS)
      set(BUILDLIBS ${BUILDLIBS} ieee-utils rng test sys)
    endif()

    # Resolve transitive dependencies
    foreach(lib ${BUILDLIBS})
      addDependencies(${lib})
    endforeach()
    # Set them as local variable
    get_property(HAVETOBUILD GLOBAL PROPERTY HAVETOBUILD_GLOBAL)

    message(STATUS "Resolved dependencies: ${HAVETOBUILD}")
else()
  set(HAVETOBUILD ${dirs} .)
endif()

# Extract sources from automake files and add tests.
foreach (dir ${HAVETOBUILD})
  file(STRINGS ${dir}/Makefile.am lines)
  foreach (line ${lines})
    if (line MATCHES "_la_SOURCES[ \t]*=")
      get_sources(${dir} "${line}" SOURCES)
      if (dir STREQUAL cblas)
        add_library(gslcblas ${SOURCES})
        target_link_libraries(gslcblas ${CMAKE_REQUIRED_LIBRARIES})
        set_target_properties(gslcblas PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON )
        add_dependencies(gslcblas copy-headers)
      else ()
        set(GSL_SOURCES ${GSL_SOURCES} ${SOURCES})
      endif ()
    elseif (line MATCHES "^test.*_SOURCES[ \t]*=")
      get_sources(${dir} "${line}" SOURCES)
      string(REGEX REPLACE "([^=]*)_SOURCES.*" "\\1" suffix ${line})
      if (SOURCES MATCHES "\\((.+)_SOURCES\\)")
          set(SOURCES ${${CMAKE_MATCH_1}})
      endif()
      set(${suffix} ${SOURCES})
      add_gsl_test("${dir}_${suffix}" ${SOURCES})
     endif ()
  endforeach ()
endforeach ()

if (BUILD_SHARED_LIBS)
  include(CheckCCompilerFlag)
  check_c_compiler_flag(-fPIC HAVE_FPIC)
  if (HAVE_FPIC)
    add_definitions(-fPIC)
  endif ()
  if (WIN32)
    # only needed for global variables that must be exported.  Exporting of
    # all functions is done with target property WINDOWS_EXPORT_ALL_SYMBOLS.
    add_definitions(-DGSL_DLL)
  endif()
endif ()

if(BUILD_SHARED_LIBS)
    add_library(${LIB_NAME} SHARED ${GSL_SOURCES} ${GSL_HEADER_PATHS})
    set_target_properties (${LIB_NAME} PROPERTIES
        VERSION ${VERSION}
        SOVERSION ${GSL_MAJOR_VERSION}
        COMPILE_DEFINITIONS DLL_EXPORT
        WINDOWS_EXPORT_ALL_SYMBOLS ON)
elseif(OSX_FRAMEWORK)
    # set(HHEADERS
    #     ${CMAKE_SOURCE_DIR}/gsl_version.h
    #     ${CMAKE_SOURCE_DIR}/gsl_types.h
    # )
    set_property(SOURCE ${GSL_HEADER_PATHS} PROPERTY MACOSX_PACKAGE_LOCATION "Headers/${PROJECT_NAME}")
    add_library(${LIB_NAME} SHARED ${GSL_SOURCES} ${GSL_HEADER_PATHS})
    set_target_properties(${LIB_NAME} PROPERTIES
      FRAMEWORK TRUE
      FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
      MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
      MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
      MACOSX_FRAMEWORK_IDENTIFIER org.gnu.libgsl
      XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
      # PUBLIC_HEADER "${HHEADERS}"
      VERSION ${VERSION}
      SOVERSION ${GSL_MAJOR_VERSION}
      )
else()
    add_library(${LIB_NAME} STATIC ${GSL_SOURCES} ${GSL_HEADER_PATHS})
endif()

target_include_directories(${LIB_NAME} 
    PRIVATE .
    PUBLIC $<BUILD_INTERFACE:${${PROJECT_NAME}_BINARY_DIR}>
)
target_include_directories(gslcblas
    PUBLIC 
      $<BUILD_INTERFACE:${${PROJECT_NAME}_BINARY_DIR}>
      $<BUILD_INTERFACE:${${PROJECT_NAME}_SOURCE_DIR}>
)

if(TARGET gslcblas)
    target_link_libraries(${LIB_NAME} gslcblas)
    target_include_directories(gslcblas
        PUBLIC 
          $<BUILD_INTERFACE:${${PROJECT_NAME}_BINARY_DIR}>
          $<BUILD_INTERFACE:${${PROJECT_NAME}_SOURCE_DIR}>
    )
endif()

add_dependencies(${LIB_NAME} copy-headers)

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

set(EXPORT_TARGETS ${LIB_NAME})
if(TARGET gslcblas)
    set(EXPORT_TARGETS ${EXPORT_TARGETS} gslcblas)
endif()

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    install(TARGETS ${EXPORT_TARGETS}
        EXPORT ${PACKAGE_UPPER_NAME}Targets
        RUNTIME DESTINATION ${INSTALL_BIN_DIR}
        LIBRARY DESTINATION ${INSTALL_LIB_DIR}
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
        INCLUDES DESTINATION ${INSTALL_INC_DIR}
        FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})
endif()

if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL)
    install(FILES ${GSL_HEADER_PATHS} DESTINATION "${INSTALL_INC_DIR}/${PROJECT_NAME}")
    install(FILES ${CMAKE_BINARY_DIR}/gsl.pc DESTINATION "${INSTALL_LIB_DIR}/pkgconfig")
endif()

# Export package ===============================================================

# Add path to includes to build-tree export
target_include_directories(${LIB_NAME} INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

if(HAVE_INLINE)
    target_compile_definitions(${LIB_NAME} INTERFACE HAVE_INLINE)
endif()
if(HAVE_C99_INLINE)
    target_compile_definitions(${LIB_NAME} INTERFACE HAVE_C99_INLINE)
endif()

# Add all targets to the build-tree export set
export(TARGETS ${EXPORT_TARGETS}
    FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

if(REGISTER_PACKAGE)
    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    export(PACKAGE ${PACKAGE_UPPER_NAME})
endif()

# Create the <Package>Config.cmake file
configure_file(cmake/PackageConfig.cmake.in
    ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    # Install the <Package>Config.cmake
    install(FILES
      ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
      DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)

    # Install the export set for use with the install-tree
    install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
endif()

# Archiving ====================================================================

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
set(CPACK_PACKAGE_RELOCATABLE TRUE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_GENERATOR "ZIP")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_STRIP_FILES TRUE)

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

include(CPack)