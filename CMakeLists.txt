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

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(gsl)

# Some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# Set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
  set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/Applications" CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR "${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers" CACHE INTERNAL "Installation directory for headers" FORCE)
  set(SKIP_INSTALL_HEADERS OFF)
  set(SKIP_INSTALL_EXECUTABLES ON)
  set(SKIP_INSTALL_FILES ON)
  set(SKIP_INSTALL_EXPORT ON)
  set(CMAKE_MACOSX_RPATH ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_FULL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_FULL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${CMAKE_INSTALL_FULL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_DOC_DIR ${CMAKE_INSTALL_FULL_DOCDIR} CACHE INTERNAL "Share directory for data" FORCE)
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

if(BUILD_TESTS)
    enable_testing()

    # Adds a GSL test. Usage:
    #   add_gsl_test(<exename> <source> ...)
    function(add_gsl_test exename)
      if (GSL_DISABLE_TESTS)
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
          set(GSLCBLAS_TYPE STATIC)
        endif ()
        add_library(gslcblas ${GSLCBLAS_TYPE} ${SOURCES})
        target_link_libraries(gslcblas ${CMAKE_REQUIRED_LIBRARIES})
        add_dependencies(gslcblas copy-headers)
      else ()
        set(GSL_SOURCES ${GSL_SOURCES} ${SOURCES})
      endif ()
  elseif (line MATCHES "^test.*_SOURCES[ \t]*=" AND BUILD_TESTS)
      get_sources(${dir} "${line}" SOURCES)
      string(REGEX REPLACE "(.*)_SOURCES.*" "\\1" suffix ${line})
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
            if (NOT ${CMAKE_MATCH_2} STREQUAL gsl_multilarge_nlinear_df AND NOT ${CMAKE_MATCH_2} STREQUAL gsl_multilarge_nlinear_fdfvv)
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
    set(HHEADERS
        ${CMAKE_SOURCE_DIR}/gsl_version.h
        ${CMAKE_SOURCE_DIR}/gsl_types.h
    )
    add_library(${LIB_NAME} SHARED ${GSL_SOURCES} ${HHEADERS})
    set_target_properties(${LIB_NAME} PROPERTIES
      FRAMEWORK TRUE
      FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
      MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
      MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
      MACOSX_FRAMEWORK_IDENTIFIER org.gnu.libgsl
      XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
      PUBLIC_HEADER "${HHEADERS}"
      VERSION ${VERSION}
      SOVERSION ${GSL_MAJOR_VERSION}
      )
else()
    add_library(${LIB_NAME} STATIC ${GSL_SOURCES} ${GSL_HEADER_PATHS})
endif()

target_link_libraries(${LIB_NAME} gslcblas)
add_dependencies(gsl copy-headers)

if (REGISTER_PACKAGE)
    export(TARGETS gsl gslcblas FILE ${PROJECT_NAME}-exports.cmake)

    set(EXPORT_PACKAGE_NAME GSL)
    string(TOUPPER ${EXPORT_PACKAGE_NAME} EXPORT_PACKAGE_NAME_UPPER)
    set(EXPORT_PACKAGE_LIB_NAME gsl)

    export(PACKAGE ${EXPORT_PACKAGE_NAME})

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        ${CMAKE_SOURCE_DIR}/cmake/PackageConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}Config.cmake
        INSTALL_DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}ConfigVersion.cmake
        VERSION ${VERSION}
        COMPATIBILITY AnyNewerVersion )
else()
    export(TARGETS gsl gslcblas FILE ${PROJECT_NAME}-exports.cmake EXPORT_LINK_INTERFACE_LIBRARIES)
endif()

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    install(TARGETS gsl
        RUNTIME DESTINATION "${INSTALL_BIN_DIR}" COMPONENT libraries
        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}" COMPONENT libraries
        LIBRARY DESTINATION "${INSTALL_LIB_DIR}" COMPONENT libraries
        FRAMEWORK DESTINATION "${INSTALL_LIB_DIR}")
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
