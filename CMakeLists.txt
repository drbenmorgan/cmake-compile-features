# Project to demo CMake compile features for C++ standard
# Only covers GNU, {Apple}Clang and MSVC so far
cmake_minimum_required(VERSION 3.8...3.18)
if(${CMAKE_VERSION} VERSION_LESS 3.12)
  cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

project(cmake-compile-features)

#-----------------------------------------------------------------------
# Basic setup
# - Always verbose so we can see compile flags
set(CMAKE_VERBOSE_MAKEFILE ON)

# - For symbol visibility
include(GenerateExportHeader)

# - Enumerated option to allow C++ Standard selection
include(cmake/EnumeratedOption.cmake)

# - Stdlib checker
include(cmake/CheckCXXStandardLibrary.cmake)

#-----------------------------------------------------------------------
# Compiler Info
# - Print, for info, detected Compiler and Version
message(STATUS "CXX compiler ID         : '${CMAKE_CXX_COMPILER_ID}'")
message(STATUS "CXX compiler Simulate ID: '${CMAKE_CXX_SIMULATE_ID}'")
message(STATUS "CXX compiler Version    : '${CMAKE_CXX_COMPILER_VERSION}'")

#-----------------------------------------------------------------------
# C++ Standard Selection - 11, 14 or 17, or 2a
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enum_option(CMAKE_CXX_STANDARD
  DOC "C++ Standard to compile against"
  VALUES 17 20 11 14
  CASE_INSENSITIVE
  )
set(CCF_REQUIRED_FEATURES cxx_std_${CMAKE_CXX_STANDARD})
message(STATUS "CXX standard            : '${CMAKE_CXX_STANDARD}'")

#-----------------------------------------------------------------------
# Compiler features
# - Simple header-only checks
include(CheckIncludeFileCXX)

# - A very dumb wrapper round try_compile
# Yes, CheckCXXSourceCompiles does this, but only want a message, nothing else!
function(check_cxx_feature _flag)
  try_compile(${_flag} ${ARGN})
  # Can be simplified after 3.17 with CHECK_PASS/FAIL
  set(__preamble "Checking C++ feature ${_flag} -")
  if(${_flag})
    message(STATUS "${__preamble} Success")
  else()
    message(STATUS "${__preamble} Failed")
  endif()
endfunction()

# - Default checks output directory
set(testCxxFeatures_CHECK_DIR ${PROJECT_BINARY_DIR}/_cxxchecks)

#-----------------------------------------------------------------------------
# - C++ Language Feature Checks
# -- auto return type deduction
check_cxx_feature(CXX_HAS_AUTO_RETURN_TYPE
  ${testCxxFeatures_CHECK_DIR}/cxx_has_auto_return_type
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_auto_return_type.cc)

# -- __has_include
check_cxx_feature(CXX_HAS_HAS_INCLUDE
  ${testCxxFeatures_CHECK_DIR}/cxx_has_include
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_has_include.cc)

# -- Relaxed constexpr
check_cxx_feature(CXX_HAS_RELAXED_CONSTEXPR
  ${testCxxFeatures_CHECK_DIR}/cxx_relaxed_constexpr
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_relaxed_constexpr.cc)

# -- Generic lambdas
check_cxx_feature(CXX_HAS_GENERIC_LAMBDA
  ${testCxxFeatures_CHECK_DIR}/cxx_generic_lambda
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_generic_lambda.cc)

# -- Structured bindings
check_cxx_feature(CXX_HAS_STRUCTURED_BINDINGS
  ${testCxxFeatures_CHECK_DIR}/cxx_structured_bindings
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_structured_bindings.cc)

#-----------------------------------------------------------------------------
# - C++ Standard Library Feature Checks
# -- stdlib implementation
check_cxxstdlib_implementation()

# -- std::any
check_include_file_cxx(any CXXSTDLIB_HAS_ANY)
if(NOT CXXSTDLIB_HAS_ANY)
  check_include_file_cxx(experimental/any CXXSTDLIB_HAS_EXPERIMENTAL_ANY)
endif()

# -- std::filesystem (and stdlib implementation)
# 1. Which header is used
check_include_file_cxx(filesystem CXXSTDLIB_HAS_FILESYSTEM)
if(NOT CXXSTDLIB_HAS_FILESYSTEM)
  check_include_file_cxx(experimental/filesystem CXXSTDLIB_HAS_EXPERIMENTAL_FILESYSTEM)
endif()

# 2. Which library provides the implementation
# - Known options:
#   - builtin to normal stdlib
#   - GNU: stdc++fs
#   - Clang: c++fs
check_cxx_feature(CXXSTDLIB_FILESYSTEM_NATIVE
  ${testCxxFeatures_CHECK_DIR}/cxx_filesystem/native
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_filesystem.cc)

if(NOT CXXSTDLIB_FILESYSTEM_NATIVE)
  # GNU libstdc++fs
  check_cxx_feature(CXXSTDLIB_FILESYSTEM_STDCXXFS
    ${testCxxFeatures_CHECK_DIR}/cxx_filesystem/stdc++fs
    ${PROJECT_SOURCE_DIR}/cmake/check_cxx_filesystem.cc
    LINK_LIBRARIES stdc++fs)
  # LLVM libc++fs
  check_cxx_feature(CXXSTDLIB_FILESYSTEM_CXXFS
    ${testCxxFeatures_CHECK_DIR}/cxx_filesystem/c++fs
    ${PROJECT_SOURCE_DIR}/cmake/check_cxx_filesystem.cc
    LINK_LIBRARIES c++fs)
endif()

# 3. Derive name of library for use in reports
set(CXXSTDLIB_FILESYSTEM_LIBRARY "unsupported")
if(CXXSTDLIB_FILESYSTEM_NATIVE)
  set(CXXSTDLIB_FILESYSTEM_LIBRARY "native")
elseif(CXXSTDLIB_FILESYSTEM_STDCXXFS)
  set(CXXSTDLIB_FILESYSTEM_LIBRARY "stdc++fs")
elseif(CXXSTDLIB_FILESYSTEM_CXXFS)
  set(CXXSTDLIB_FILESYSTEM_LIBRARY "c++fs")
endif()

# -- (memory) make_unique
check_cxx_feature(CXX_HAS_MAKE_UNIQUE
  ${testCxxFeatures_CHECK_DIR}/cxx_make_unique
  ${PROJECT_SOURCE_DIR}/cmake/check_cxx_make_unique.cc)

# -- std::optional
check_include_file_cxx(optional CXXSTDLIB_HAS_OPTIONAL)
if(NOT CXXSTDLIB_HAS_OPTIONAL)
  check_include_file_cxx(experimental/optional CXXSTDLIB_HAS_EXPERIMENTAL_OPTIONAL)
endif()

# -- std::string_view
check_include_file_cxx(string_view CXXSTDLIB_HAS_STRING_VIEW)
if(NOT CXXSTDLIB_HAS_STRING_VIEW)
  check_include_file_cxx(experimental/string_view CXXSTDLIB_HAS_EXPERIMENTAL_STRING_VIEW)
endif()

# -- std::variant
check_include_file_cxx(variant CXXSTDLIB_HAS_VARIANT)
if(NOT CXXSTDLIB_HAS_VARIANT)
  check_include_file_cxx(experimental/variant CXXSTDLIB_HAS_EXPERIMENTAL_VARIANT)
endif()

#-----------------------------------------------------------------------------
# - Configure and build reporting application/test
configure_file(checkCXXFeatures.cc.in "${PROJECT_BINARY_DIR}/checkCXXFeatures.cc")
add_executable(checkCXXFeatures "${PROJECT_BINARY_DIR}/checkCXXFeatures.cc")

enable_testing()
add_test(NAME checkCXXFeatures COMMAND checkCXXFeatures)
