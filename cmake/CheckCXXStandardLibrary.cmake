# - Determine the C++ Standard Library Vendor and Version
#
# When included in a project via include(), perform a compile/run
# test to determine the vendor and version of the C++ standard library
# the compiler will link to.
#
# If the project is being cross-compiled, do nothing other than
# report the fact. Otherwise, the following variables are set
#
#  CXX_STDLIB_VENDOR     - Name of C++ Standard Library Vendor
#  CXX_STDLIB_VERSION    - Vendor specific version number
#
# If the vendor/version cannot be determined, the variables are set
# to NOTFOUND
#
# KNOWN ISSUE : This does not detect the vendor correctly when generating
# Xcode projects because of the way compiler/linker flags are used in
# the Xcode generator:
#  http://cmake.org/Bug/view.php?id=10552
#
# This can be worked around, but needs thought because there's an implicit
# coupling to the initial checks done in CheckCXX11Features.

#-----------------------------------------------------------------------
# Copyright (c) 2014, Ben Morgan <bmorgan.warwick@gmail.com>
#
# Distributed under the OSI-approved BSD 3-Clause License (the "License");
# see accompanying file License.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#-----------------------------------------------------------------------

if(NOT __CHECKCXXSTANDARDLIBRARY_LOADED)
  set(__CHECKCXXSTANDARDLIBRARY_LOADED 1)
  set(__CHECKCXXSTANDARDLIBRARY_DIR "${CMAKE_CURRENT_LIST_DIR}")
else()
  return()
endif()

function(check_cxxstdlib_implementation)
  if(NOT CMAKE_CXX_COMPILER_LOADED)
    message(FATAL_ERROR "No CXX compiler available to query stdlib")
  endif()

  if((NOT DEFINED CXX_STDLIB_VENDOR) OR (NOT DEFINED CXX_STDLIB_VERSION))
    if(CMAKE_CROSSCOMPILING)
      set(CXX_STDLIB_VENDOR NOTFOUND)
      set(CXX_STDLIB_VERSION NOTFOUND)
      message(STATUS "Checking C++ Library Vendor: N/A(cross compiling)")
      message(STATUS "Checking C++ Library Version: N/A(cross compiling)")
    else()
      try_run(
        CHECK_CXX_STDLIB_RESULT
        CHECK_CXX_STDLIB_COMPILE_RESULT
        ${CMAKE_CURRENT_BINARY_DIR}/CheckCXXStdLib
        ${__CHECKCXXSTANDARDLIBRARY_DIR}/CheckCXXStdLib.cpp
        RUN_OUTPUT_VARIABLE CHECK_CXX_STDLIB_OUTPUT
        )
      if(CHECK_CXX_STDLIB_COMPILE_RESULT AND NOT CHECK_CXX_STDLIB_RESULT)
        list(GET CHECK_CXX_STDLIB_OUTPUT 0 CXX_STDLIB_VENDOR)
        list(GET CHECK_CXX_STDLIB_OUTPUT 1 CXX_STDLIB_VERSION)
      else()
        set(CXX_STDLIB_VENDOR NOTFOUND)
        set(CXX_STDLIB_VERSION NOTFOUND)
      endif()
      message(STATUS "Checking C++ Library Vendor: ${CXX_STDLIB_VENDOR}")
      message(STATUS "Checking C++ Library Version: ${CXX_STDLIB_VERSION}")
    endif()
  else()
    return()
  endif()

  set(CXX_STDLIB_VENDOR ${CXX_STDLIB_VENDOR} PARENT_SCOPE)
  set(CXX_STDLIB_VERSION ${CXX_STDLIB_VERSION} PARENT_SCOPE)
endfunction()



