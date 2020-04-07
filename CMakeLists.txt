# Project to demo CMake compile features for C++ standard
# Only covers GNU, {Apple}Clang and MSVC so far
cmake_minimum_required(VERSION 3.8)
project(cmake-compile-features)

message(STATUS "CMake Version: ${CMAKE_VERSION}")

#-----------------------------------------------------------------------
# Basic setup
# - Always verbose so we can see compile flags
set(CMAKE_VERBOSE_MAKEFILE ON)

# - For symbol visibility
include(GenerateExportHeader)

# - Enumerated option to allow C++ Standard selection
include(cmake/EnumeratedOption.cmake)

# - Include modules for helping to check C++ stdlib features
include(cmake/CheckCXXFeature.cmake)
include(cmake/CheckCXXStandardLibrary.cmake)

#-----------------------------------------------------------------------
# Compiler Info
# - Print, for info, detected Compiler and Version
message(STATUS "CXX compiler ID         : '${CMAKE_CXX_COMPILER_ID}'")
message(STATUS "CXX compiler Simulate ID: '${CMAKE_CXX_SIMULATE_ID}'")
message(STATUS "CXX compiler Version    : '${CMAKE_CXX_COMPILER_VERSION}'")

#-----------------------------------------------------------------------
# C++ Standard Selection - 11, 14 or 17, or 2a
enum_option(CMAKE_CXX_STANDARD
  DOC "C++ Standard to compile against"
  VALUES 17 20 11 14
  CASE_INSENSITIVE
  )
set(CCF_REQUIRED_FEATURES cxx_std_${CMAKE_CXX_STANDARD})
#-----------------------------------------------------------------------
# Compiler features
# - Do NOT want vendor extensions (e.g. no --std=gnu++11)
set(CMAKE_CXX_EXTENSIONS OFF)

# - Print list of C++ features that CMake *knows* compiler to support
foreach(_cxxstd 11 14 17 20)
  message(STATUS "List of supported CXX${_cxxstd} features:")
  foreach(_f ${CMAKE_CXX${_cxxstd}_COMPILE_FEATURES})
    message("  ${_f}")
  endforeach()
endforeach()

# - Can also write a compiler detection header. This is useful
# for providing workarounds for features not provided by the compiler/stdlib
# See also:
#  https://cmake.org/cmake/help/v3.8/module/WriteCompilerDetectionHeader.html
#
include(WriteCompilerDetectionHeader)
write_compiler_detection_header(
  # Public, detail or private header? Probably private unless CCF
  # exposes types in other public interfaces
  FILE "${CMAKE_CURRENT_BINARY_DIR}/ccf/detail/ccf_compiler_support.hpp"
  PREFIX CCF
  COMPILERS AppleClang Clang GNU Intel MSVC
  # Separate headers on a per compiler basis for clarity
  OUTPUT_DIR ccf/detail/Compilers
  OUTPUT_FILES_VAR CCF_COMPILER_HEADERS
  FEATURES
    cxx_thread_local
  PROLOG "// This is a custom prolog"
  EPILOG "// This is a custom epilog"
  )

# - Check standard library implementation and features
# Important to distinguish between the compiler and the eventual
# standard library it links to. For example, Clang on Linux may link to
# the GNU library, Intel may use GNU library or its own.
#
# Here, we actually want to confirm the compiler as configured so far
# can compile, link and run test programs that exercise the standard
# library feature to be checked.
#
# - To begin with, determine the actual implementation and version.
# This is informational rather than direct useful, e.g. may export
# this info the the project config files
check_cxxstdlib_implementation()

# Check lib features - these are things we need but for which CMake
# provides no feature detection (i.e. are implementation details of
# the Standard C++ library being used)
# Works, but can't then add these to list of known/supported features
# and get automatic compiler flag support
# Can always fail at configure stage based on truth of HAS_CXX_...
# variables, or add these into the PROLOG/EPILOG entries of the compiler
# detection header (e.g. to provide workarounds)
check_cxx_feature("cxx_memory_shared_ptr" HAS_CXX_MEMORY_SHARED_PTR)
check_cxx_feature("cxx_memory_unique_ptr" HAS_CXX_MEMORY_UNIQUE_PTR)
check_cxx_feature("cxx_memory_weak_ptr" HAS_CXX_MEMORY_WEAK_PTR)
check_cxx_feature("cxx_memory_make_unique" HAS_CXX_MEMORY_MAKE_UNIQUE)
check_cxx_feature("cxx_unordered_map" HAS_CXX_UNORDERED_MAP)
check_cxx_feature("cxx_unordered_set" HAS_CXX_UNORDERED_SET)
check_cxx_feature("cxx_random" HAS_CXX_RANDOM)
check_cxx_feature("cxx_thread_thread" HAS_CXX_THREAD_THREAD)

# - configure our custom header to supply implementation workarounds
# based on the above values. However, note that this effectively hardcodes
# for one stdlib implementation, so the header *probably* should not
# be installed.
configure_file(ccf/detail/ccf_stdlib_support.hpp.in
  ccf/detail/ccf_stdlib_support.hpp
  )

#-----------------------------------------------------------------------
# Compile this project's library from the sources...
add_library(ccf-features SHARED ccf/ccf.hpp ccf/ccf.cpp)

#... with the required compile features
# PUBLIC means that clients of libccf will inherit the features of ccf
# and hence be compiled with the appropriate flags
target_compile_features(ccf-features PUBLIC ${CCF_REQUIRED_FEATURES})

#... and the needed include paths
target_include_directories(ccf-features
  PUBLIC
  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

# - and an export header
generate_export_header(ccf-features
  BASE_NAME ccf
  EXPORT_FILE_NAME ccf/ccf_export.h
  )

#-----------------------------------------------------------------------
# Now the project program (equally, this could be a client program)
add_executable(ccf-program ccf-program.cpp)

#... and link it to the library. Even though we haven't set compile_features
# for the program, it "inherits" the PUBLIC ones from the target.
# In consequence, it's compiled with the appropriate flags!
target_link_libraries(ccf-program ccf-features)



#-----------------------------------------------------------------------
# Install and Support files
# - Here, we would like clients to automatically pick up needed
#   compiler requirements on the C++ Standard
# What you should find is that the "ccf-exports.cmake" file sets up an
# imported target for libccf, and sets the INTERFACE_COMPILE_FEATURES
# to those listed in 'CCF_REQUIRED_FEATURES'. That means that clients
# compiling with CMake and linking to the library will also require
# those features (and hence be compiled against the required standard).
# It's basically the same behaviour seen above with ccf-program
# The issue of course is that other features like shared_ptr and so
# on cannot be added to this list - this is where listing the stdlib
# implementation and details may be useful.

include(GNUInstallDirs)
set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake")

install(TARGETS ccf-features ccf-program EXPORT ccf-exports DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES
  ccf/ccf.hpp
  "${CMAKE_CURRENT_BINARY_DIR}/ccf/ccf_export.h"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ccf"
  )
install(DIRECTORY
  "${CMAKE_CURRENT_BINARY_DIR}/ccf/detail"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ccf/"
  )


include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${PROJECT_BINARY_DIR}/ccf-configversion.cmake
  VERSION 1.2.3
  COMPATIBILITY SameMajorVersion
  )

# - Build tree config file(s)
set(INSTALL_INCDIR "${PROJECT_SOURCE_DIR}")

configure_package_config_file(cmake/ccf-config.cmake.in
  ${PROJECT_BINARY_DIR}/ccf-config.cmake
  INSTALL_DESTINATION ${PROJECT_BINARY_DIR}
  PATH_VARS INSTALL_INCDIR
  INSTALL_PREFIX ${PROJECT_BINARY_DIR}
  )

export(EXPORT ccf-exports NAMESPACE "ccf::" FILE "${PROJECT_BINARY_DIR}/ccf-exports.cmake")

# - Install Tree config files
set(INSTALL_INCDIR "${CMAKE_INSTALL_INCLUDEDIR}")

configure_package_config_file(cmake/ccf-config.cmake.in
  ${PROJECT_BINARY_DIR}/InstallTreeFiles/ccf-config.cmake
  INSTALL_DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf"
  PATH_VARS INSTALL_INCDIR
  )

install(EXPORT ccf-exports NAMESPACE "ccf::" DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf")
install(FILES ${PROJECT_BINARY_DIR}/InstallTreeFiles/ccf-config.cmake
  DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf"
  )
