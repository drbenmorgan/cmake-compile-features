# Project to demo CMake compile features for C++ standard

# Want to support gcc 4.9, Clang 3.5/6, Intel 15 and VS2015
cmake_minimum_required(VERSION 3.2)
project(cmake-compile-features)

# - Always verbose so user can see compile flags
set(CMAKE_VERBOSE_MAKEFILE ON)
#-----------------------------------------------------------------------
# Compiler Info
# - Print, for info, detected Compiler and Version
message(STATUS "CXX compiler ID: '${CMAKE_CXX_COMPILER_ID}'")
message(STATUS "CXX compiler Version: '${CMAKE_CXX_COMPILER_VERSION}'")

#-----------------------------------------------------------------------
# Compiler features
# - Do NOT want vendor extensions (e.g. no --std=gnu++11
set(CMAKE_CXX_EXTENSIONS OFF)

# - Print list of C++ features that CMake *knows* about, i.e. can check
# for. Does *not* mean compiler supports them
# See also
# http://www.cmake.org/cmake/help/v3.2/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html
message(STATUS "List of known CXX features known to CMake")
get_property(_cxx_known_features GLOBAL PROPERTY CMAKE_CXX_KNOWN_FEATURES)
foreach(_f ${_cxx_known_features})
  message("  ${_f}")
endforeach()

# - whereas CMAKE_CXX_COMPILE_FEATURES should list those the compiler
#   actually supports
# - ?How to add further checks for features not
message(STATUS "List of supported CXX features")
get_property(_cxx_compile_features GLOBAL PROPERTY CMAKE_CXX_COMPILE_FEATURES)
foreach(_f ${CMAKE_CXX_COMPILE_FEATURES})
  message("  ${_f}")
endforeach()

#-----------------------------------------------------------------------
# Based on Geant4 initial support, list absolute required features
#
set(THIS_REQUIRED_FEATURES
  cxx_auto_type
  cxx_range_for
  cxx_generalized_initializers
  cxx_nullptr
  cxx_alias_templates
  cxx_constexpr
  cxx_strong_enums
  cxx_deleted_functions
  cxx_override
  cxx_final
  cxx_delegating_constructors
  cxx_inheriting_constructors
  cxx_defaulted_functions
  # Smart pointers more a library feature?
  cxx_lambdas
  # Hashed containers more a library feature?
  # Random numbers more a library feature?

  # - Thread local? Yes, though on AppleClang platforms, see this:
  #http://stackoverflow.com/questions/28094794/why-does-apple-clang-disallow-c11-thread-local-when-official-clang-supports
  #cxx_thread_local
  # Rest of concurrency more a library feature?
  )


#-----------------------------------------------------------------------
# Try and compile a program with the required feature list
add_executable(basic-program basic-program.cpp)
target_compile_features(basic-program PUBLIC ${THIS_REQUIRED_FEATURES})

