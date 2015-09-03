# - Check which parts of the C++11 standard the compiler supports
#
# Though CMake now supports Clang-style compiler features, this does
# not (at present?) check for library support features such as headers
# and implementation (e.g. <regex>, <memory> and std::shared_ptr).
#
# This is a basic function to check that a source exercising a
# particular library feature compiles (and optional runs if not
# cross-compiling)
#
# Do seem to have internal CMake variables listing required flags for
# current compiler and given standard:
#
#  CMAKE_CXX<STD>_STANDARD_COMPILE_OPTION
#  CMAKE_CXX<STD>_EXTENSION_COMPILE_OPTION
#
# Here, <STD> is 98, 11, 14 etc
# - Also need to worry about Clang's stdlib arg...
#
# Not clear yet how best to split checks between different Standards.
# E.g. Code may only use C++11 itself, but clients may want to compile
# against others.

# Copyright 2011,2012 Rolf Eike Beer <eike@sf-mail.de>
# Copyright 2012 Andreas Weis
# Copyright 2014,2015 Ben Morgan <Ben.Morgan@warwick.ac.uk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holders nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

if(NOT __CHECKCXXFEATURE_LOADED)
  set(__CHECKCXXFEATURE_LOADED 1)
else()
  return()
endif()

#-----------------------------------------------------------------------
# Let's see if the compile options are set
message(STATUS "CMAKE_CXX11_STANDARD_COMPILE_OPTION: ${CMAKE_CXX11_STANDARD_COMPILE_OPTION}")
message(STATUS "CMAKE_CXX14_STANDARD_COMPILE_OPTION: ${CMAKE_CXX14_STANDARD_COMPILE_OPTION}")

set(__CHECKCXXFEATURE_DIR "${CMAKE_CURRENT_LIST_DIR}")

#-----------------------------------------------------------------------
# Check that compiler support C++11 FEATURE_NAME, setting RESULT_VAR to
# TRUE if feature is present
function(check_cxx11_feature FEATURE_NAME RESULT_VAR)
  # Factor out standard id
  set(_CF_CXX_STANDARD 11)

  if(NOT DEFINED ${RESULT_VAR})
    set(_bindir "${CMAKE_BINARY_DIR}/CheckCXXFeature/${FEATURE_NAME}")
    set(_SRCFILE_BASE ${__CHECKCXXFEATURE_DIR}/cxx${_CF_CXX_STANDARD}-test-${FEATURE_NAME})
    set(_LOG_NAME "\"${FEATURE_NAME}\"")
    message(STATUS "Checking support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}")

    set(_SRCFILE "${_SRCFILE_BASE}.cpp")
    set(_SRCFILE_FAIL "${_SRCFILE_BASE}_fail.cpp")
    set(_SRCFILE_FAIL_COMPILE "${_SRCFILE_BASE}_fail_compile.cpp")

    if(NOT EXISTS "${_SRCFILE}")
      message(STATUS "Checking support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}: not supported (no test available)")
      set(${RESULT_VAR} FALSE CACHE INTERNAL "support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}")
      return()
    endif()

    if(CMAKE_CROSSCOMPILING)
      try_compile(${RESULT_VAR} "${_bindir}" "${_SRCFILE}"
        COMPILE_DEFINITIONS "${CMAKE_CXX${_CF_CXX_STANDARD}_STANDARD_COMPILE_OPTION}")
      if(${RESULT_VAR} AND EXISTS ${_SRCFILE_FAIL})
        try_compile(${RESULT_VAR} "${_bindir}_fail" "${_SRCFILE_FAIL}"
          COMPILE_DEFINITIONS "${CMAKE_CXX${_CF_CXX_STANDARD}_STANDARD_COMPILE_OPTION}")
      endif()
    else()
      try_run(_RUN_RESULT_VAR _COMPILE_RESULT_VAR
        "${_bindir}" "${_SRCFILE}"
        COMPILE_DEFINITIONS "${CMAKE_CXX${_CF_CXX_STANDARD}_STANDARD_COMPILE_OPTION}")
      if(_COMPILE_RESULT_VAR AND NOT _RUN_RESULT_VAR)
        set(${RESULT_VAR} TRUE)
      else()
        set(${RESULT_VAR} FALSE)
      endif()

      if(${RESULT_VAR} AND EXISTS ${_SRCFILE_FAIL})
        try_run(_RUN_RESULT_VAR _COMPILE_RESULT_VAR
          "${_bindir}_fail" "${_SRCFILE_FAIL}"
          COMPILE_DEFINITIONS "${CMAKE_CXX${_CF_CXX_STANDARD}_STANDARD_COMPILE_OPTION}")
        if(_COMPILE_RESULT_VAR AND _RUN_RESULT_VAR)
          set(${RESULT_VAR} TRUE)
        else()
          set(${RESULT_VAR} FALSE)
        endif()
      endif()
    endif()

    if(${RESULT_VAR} AND EXISTS ${_SRCFILE_FAIL_COMPILE})
      try_compile(_TMP_RESULT "${_bindir}_fail_compile" "${_SRCFILE_FAIL_COMPILE}"
        COMPILE_DEFINITIONS "${CMAKE_CXX${_CF_CXX_STANDARD}_STANDARD_COMPILE_OPTION}")
      if(_TMP_RESULT)
        set(${RESULT_VAR} FALSE)
      else()
        set(${RESULT_VAR} TRUE)
      endif()
    endif()

    if(${RESULT_VAR})
      message(STATUS "Checking support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}: works")
    else()
      message(STATUS "Checking support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}: not supported")
    endif()

    set(${RESULT_VAR} ${${RESULT_VAR}} CACHE INTERNAL "support for ${_LOG_NAME} in C++${_CF_CXX_STANDARD}")
  endif()
endfunction()



