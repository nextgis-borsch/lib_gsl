################################################################################
# Project:  Lib GSL
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2017-2018, NextGIS <info@nextgis.com>
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

# Fix windows build
if(WIN32)
    file(READ ieee-utils/env.c _ENV_C_CONTENTS)
    string(REPLACE
"extern const char *fp_env_string;
    p = fp_env_string;"
"if (p == 0) return;
  if (*p == '\\0') return ;"
    _ENV_C_CONTENTS
    "${_ENV_C_CONTENTS}"
    )
    file(WRITE ieee-utils/env.c "${_ENV_C_CONTENTS}")
    file(WRITE ${CMAKE_BINARY_DIR}/unistd.h "/* nop */")
    add_definitions(-DHIDE_INLINE_STATIC)
endif()

if(BUILD_TESTING)
    enable_testing()

    # Adds a GSL test. Usage:
    #   add_gsl_test(<exename> <source> ...)
    function(add_gsl_test exename)
      if (GSL_DISABLE_TESTS OR exename MATCHES specfunc_test)
        return()
      endif ()
      add_executable(${exename} ${ARGN})
      target_link_libraries(${exename} gsl)
      add_test(${exename} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${exename})
    endfunction()
endif()

file(GLOB GSL_HEADER_PATHS "${CMAKE_SOURCE_DIR}/gsl*.h")
file(GLOB dirs "${CMAKE_SOURCE_DIR}/*")
foreach (dir ${dirs})
  if (NOT (dir MATCHES "gsl$"))
    file(GLOB headers "${dir}/gsl*.h")
    set(GSL_HEADER_PATHS ${GSL_HEADER_PATHS} ${headers})
  endif ()
endforeach()

foreach (path ${GSL_HEADER_PATHS})
  get_filename_component(name ${path} NAME)
  set(GSL_HEADERS ${GSL_HEADERS} gsl/${name})
endforeach ()

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/copy-headers.cmake "
  file(MAKE_DIRECTORY gsl)
  foreach (path ${GSL_HEADER_PATHS})
    get_filename_component(filename \${path} NAME)
    configure_file(\${path} ${CMAKE_BINARY_DIR}/gsl/\${filename} COPYONLY)
  endforeach ()")

add_custom_command(OUTPUT ${GSL_HEADERS}
  COMMAND ${CMAKE_COMMAND} -P copy-headers.cmake)
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

# Extract sources from automake files and add tests.
foreach (dir "." ${dirs})
  file(STRINGS ${dir}/Makefile.am lines)
  foreach (line ${lines})
    if (line MATCHES "_la_SOURCES[ \t]*=")
      get_sources(${dir} "${line}" SOURCES)
      if (dir STREQUAL cblas)
        # Build gslcblas as a static library on MSVC because it doesn't have a .def file.
        if (MSVC OR OSX_FRAMEWORK)
          set(GSLCBLAS_TYPE OBJECT) # STATIC)
          set(GSL_SOURCES ${GSL_SOURCES} $<TARGET_OBJECTS:gslcblas>)
        endif ()
        add_library(gslcblas ${GSLCBLAS_TYPE} ${SOURCES})
        # target_link_libraries(gslcblas ${CMAKE_REQUIRED_LIBRARIES})
        add_dependencies(gslcblas copy-headers)
      else ()
        set(GSL_SOURCES ${GSL_SOURCES} ${SOURCES})
      endif ()
  elseif (line MATCHES "^test.*_SOURCES[ \t]*=" AND BUILD_TESTING)
      get_sources(${dir} "${line}" SOURCES)
      string(REGEX REPLACE "(.*)_SOURCES.*" "\\1" suffix ${line})
      add_gsl_test("${dir}_${suffix}" ${SOURCES})
    endif ()
  endforeach ()
endforeach ()

set(DEPRICATED_FUNCTIONS
    gsl_multilarge_nlinear_df
    gsl_multilarge_nlinear_fdfvv
    gsl_block_complex_long_double_fprintf
    gsl_block_complex_long_double_fscanf
    gsl_block_complex_long_double_raw_fprintf
    gsl_block_complex_long_double_raw_fscanf
    gsl_block_long_double_fprintf
    gsl_block_long_double_fscanf
    gsl_block_long_double_raw_fprintf
    gsl_block_long_double_raw_fscanf
    gsl_matrix_complex_long_double_fprintf
    gsl_matrix_complex_long_double_fscanf
    gsl_matrix_long_double_fprintf
    gsl_matrix_long_double_fscanf
    gsl_vector_complex_long_double_fprintf
    gsl_vector_complex_long_double_fscanf
    gsl_vector_long_double_fprintf
    gsl_vector_long_double_fscanf
)

if(HAVE_INLINE)
    set(DEPRICATED_FUNCTIONS ${DEPRICATED_FUNCTIONS}
        gsl_combination_get gsl_complex_poly_complex_eval gsl_complex_rect
        gsl_linalg_givens_gv gsl_matrix_char_const_ptr
        gsl_matrix_char_get gsl_matrix_char_ptr gsl_matrix_char_set
        gsl_matrix_complex_const_ptr gsl_matrix_complex_float_const_ptr gsl_matrix_complex_float_get gsl_matrix_complex_float_ptr gsl_matrix_complex_float_set gsl_matrix_complex_get
        gsl_matrix_complex_long_double_const_ptr gsl_matrix_complex_long_double_get gsl_matrix_complex_long_double_ptr gsl_matrix_complex_long_double_set gsl_matrix_complex_ptr
        gsl_matrix_complex_set gsl_matrix_const_ptr gsl_matrix_float_const_ptr gsl_matrix_float_get
        gsl_matrix_float_ptr gsl_matrix_float_set gsl_matrix_get gsl_matrix_int_const_ptr
        gsl_matrix_int_get gsl_matrix_int_ptr gsl_matrix_int_set gsl_matrix_long_const_ptr
        gsl_matrix_long_double_const_ptr gsl_matrix_long_double_get gsl_matrix_long_double_ptr gsl_matrix_long_double_set gsl_matrix_long_get
        gsl_matrix_long_ptr gsl_matrix_long_set gsl_matrix_ptr gsl_matrix_set
        gsl_matrix_short_const_ptr gsl_matrix_short_get gsl_matrix_short_ptr gsl_matrix_short_set
        gsl_matrix_uchar_const_ptr gsl_matrix_uchar_get gsl_matrix_uchar_ptr gsl_matrix_uchar_set
        gsl_matrix_uint_const_ptr gsl_matrix_uint_get gsl_matrix_uint_ptr gsl_matrix_uint_set
        gsl_matrix_ulong_const_ptr gsl_matrix_ulong_get gsl_matrix_ulong_ptr
        gsl_matrix_ulong_set gsl_matrix_ushort_const_ptr gsl_matrix_ushort_get
        gsl_matrix_ushort_ptr gsl_matrix_ushort_set gsl_multiset_get gsl_permutation_get
        gsl_poly_complex_eval gsl_poly_dd_eval gsl_pow_2 gsl_pow_3 gsl_pow_4 gsl_pow_5
        gsl_pow_6 gsl_pow_7 gsl_pow_8 gsl_pow_9 gsl_qrng_get gsl_rng_get gsl_rng_uniform
        gsl_rng_uniform_int gsl_vector_char_const_ptr gsl_vector_char_get
        gsl_vector_char_ptr gsl_vector_char_set
        gsl_vector_complex_const_ptr gsl_vector_complex_float_const_ptr gsl_vector_complex_float_get gsl_vector_complex_float_ptr gsl_vector_complex_float_set gsl_vector_complex_get
        gsl_vector_complex_long_double_const_ptr gsl_vector_complex_long_double_get gsl_vector_complex_long_double_ptr gsl_vector_complex_long_double_set gsl_vector_complex_ptr
        gsl_vector_complex_set gsl_vector_const_ptr
        gsl_vector_float_const_ptr gsl_vector_float_get
        gsl_vector_float_ptr gsl_vector_float_set gsl_vector_get
        gsl_vector_int_const_ptr gsl_vector_int_get
        gsl_vector_int_ptr gsl_vector_int_set gsl_vector_long_const_ptr
        gsl_vector_long_double_const_ptr gsl_vector_long_double_get gsl_vector_long_double_ptr gsl_vector_long_double_set gsl_vector_long_get
        gsl_vector_long_ptr gsl_vector_long_set gsl_vector_ptr gsl_vector_set
        gsl_vector_short_const_ptr  gsl_vector_short_get gsl_vector_short_ptr gsl_vector_short_set
        gsl_vector_uchar_const_ptr  gsl_vector_uchar_get gsl_vector_uchar_ptr gsl_vector_uchar_set
        gsl_vector_uint_const_ptr gsl_vector_uint_get gsl_vector_uint_ptr gsl_vector_uint_set
        gsl_vector_ulong_const_ptr  gsl_vector_ulong_get gsl_vector_ulong_ptr
        gsl_vector_ulong_set gsl_vector_ushort_const_ptr  gsl_vector_ushort_get
        gsl_vector_ushort_ptr gsl_vector_ushort_set gsl_rng_uniform_pos
        gsl_interp_bsearch gsl_poly_eval
    )
endif()

if (BUILD_SHARED_LIBS)
  include(CheckCCompilerFlag)
  check_c_compiler_flag(-fPIC HAVE_FPIC)
  if (HAVE_FPIC)
    add_definitions(-fPIC)
  endif ()
  if (WIN32)
    add_definitions(-DGSL_DLL)
    # Extract function names from header and generate a .def file.
    file(WRITE gsl.def "LIBRARY GSL\nEXPORTS\n")
    foreach (header ${GSL_HEADER_PATHS})
      file(READ ${header} content)
      string(REGEX REPLACE
        "/\\*([^*]|[\r\n]|(\\*+([^*/]|[\r\n])))*\\*+/" " " content "${content}")
      set(RE "\n([^\n]*[ *])?(gsl_[A-Za-z0-9_]+)[ ]*\\(")
      string(REGEX MATCHALL "${RE}" candidates "${content}")
      foreach (line ${candidates})
        if (NOT line MATCHES typedef AND line MATCHES "${RE}")
            list(FIND DEPRICATED_FUNCTIONS ${CMAKE_MATCH_2} DEPRICATED_FUNCTION_INDEX)
            if (${DEPRICATED_FUNCTION_INDEX} EQUAL -1)
                file(APPEND gsl.def "   ${CMAKE_MATCH_2}\n")
            endif()
        endif ()
      endforeach ()

      set(RE "\n([^\n]*[ *])?(cblas_[A-Za-z0-9_]+)[ ]*\\(")
      string(REGEX MATCHALL "${RE}" candidates "${content}")
      foreach (line ${candidates})
          if (NOT line MATCHES typedef AND line MATCHES "${RE}")
              list(FIND DEPRICATED_FUNCTIONS ${CMAKE_MATCH_2} DEPRICATED_FUNCTION_INDEX)
              if (${DEPRICATED_FUNCTION_INDEX} EQUAL -1)
                  file(APPEND gsl.def "   ${CMAKE_MATCH_2}\n")
              endif()
          endif ()
        endforeach ()
    endforeach ()
    set(GSL_SOURCES ${GSL_SOURCES} gsl.def)
  endif ()
endif ()

set(LIB_NAME ${PROJECT_NAME})
if(BUILD_SHARED_LIBS)
    add_library(${LIB_NAME} SHARED ${GSL_SOURCES} ${GSL_HEADER_PATHS})
    set_target_properties (${LIB_NAME} PROPERTIES
        VERSION ${VERSION}
        SOVERSION ${GSL_MAJOR_VERSION}
        COMPILE_DEFINITIONS DLL_EXPORT)
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

if(NOT MSVC AND NOT OSX_FRAMEWORK)
target_link_libraries(${LIB_NAME} gslcblas)
endif()
add_dependencies(gsl copy-headers)

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    install(TARGETS ${LIB_NAME}
        EXPORT ${PACKAGE_UPPER_NAME}Targets
        RUNTIME DESTINATION ${INSTALL_BIN_DIR}
        LIBRARY DESTINATION ${INSTALL_LIB_DIR}
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
        INCLUDES DESTINATION ${INSTALL_INC_DIR}
        FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})
    if(NOT MSVC AND NOT OSX_FRAMEWORK)
        install(TARGETS gslcblas
            RUNTIME DESTINATION "${INSTALL_BIN_DIR}" COMPONENT libraries
            ARCHIVE DESTINATION "${INSTALL_LIB_DIR}" COMPONENT libraries
            LIBRARY DESTINATION "${INSTALL_LIB_DIR}" COMPONENT libraries)
        endif()
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
export(TARGETS ${LIB_NAME}
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
