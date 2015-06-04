# Project to demo CMake compile features for C++ standard

# Want to support gcc 4.9, Clang 3.5/6, Intel 15 and VS2015
cmake_minimum_required(VERSION 3.2)
project(cmake-compile-features)

# - Always verbose so user can see compile flags
set(CMAKE_VERBOSE_MAKEFILE ON)

# - Enumerated option
include(cmake/EnumeratedOption.cmake)

# - Include module for helping to check C++ stdlib features
include(cmake/CheckCXXFeature.cmake)


#-----------------------------------------------------------------------
# Compiler Info
# - Print, for info, detected Compiler and Version
message(STATUS "CXX compiler ID: '${CMAKE_CXX_COMPILER_ID}'")
message(STATUS "CXX compiler Version: '${CMAKE_CXX_COMPILER_VERSION}'")

#-----------------------------------------------------------------------
# C++ Standard Selection - 11, 14 or 17
enum_option(BUILD_CXX_STANDARD
  DOC "C++ Standard to compile against"
  VALUES 11 14 17
  CASE_INSENSITIVE
  )


#-----------------------------------------------------------------------
# Compiler features
# - Do NOT want vendor extensions (e.g. no --std=gnu++11
set(CMAKE_CXX_EXTENSIONS OFF)

# - Print list of C++ features that CMake *knows* about, i.e. can check
# for. Does *not* mean compiler supports them
# See also
# http://www.cmake.org/cmake/help/v3.2/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html
message(STATUS "List of CXX features known to CMake")
get_property(_cxx_known_features GLOBAL PROPERTY CMAKE_CXX_KNOWN_FEATURES)
foreach(_f ${_cxx_known_features})
  message("  ${_f}")
endforeach()

# - whereas CMAKE_CXX_COMPILE_FEATURES should list those the compiler
#   actually supports
message(STATUS "List of supported CXX features")
foreach(_f ${CMAKE_CXX_COMPILE_FEATURES})
  message("  ${_f}")
endforeach()

#-----------------------------------------------------------------------
# Based on Geant4 initial support, list absolute required features
# These are CMake compile features
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
  # Rest of concurrency more a library feature?
  )

# Check lib features - these are things we need but for which CMake
# provides no feature detection (i.e. are implementation details of
# the Standard C++ library being used)
# Works, but can't then add these to list of known/supported features...
# Can always fail at configure stage based on truth of HAS_CXX_...
# variables
check_cxx11_feature("memory_shared_ptr" HAS_CXX_MEMORY_SHARED_PTR)
check_cxx11_feature("memory_unique_ptr" HAS_CXX_MEMORY_UNIQUE_PTR)
check_cxx11_feature("memory_weak_ptr" HAS_CXX_MEMORY_WEAK_PTR)
check_cxx11_feature("memory_make_unique" HAS_CXX_MEMORY_MAKE_UNIQUE)

#-----------------------------------------------------------------------
# Try and compile a program with the required feature list
# - When building, the appropriate flag should be added to the compile
# command, but of course doesn't account for additional stdlib features
add_executable(basic-program basic-program.cpp)
target_compile_features(basic-program PUBLIC ${THIS_REQUIRED_FEATURES})


#-----------------------------------------------------------------------
# Now a library
add_library(ccf SHARED ccf.hpp ccf.cpp)
target_compile_features(ccf PUBLIC ${THIS_REQUIRED_FEATURES})

#-----------------------------------------------------------------------
# Install...
include(GNUInstallDirs)
set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake")

install(TARGETS ccf EXPORT ccf-exports DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES ccf.hpp DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

#-----------------------------------------------------------------------
# Support files
# - Here, we would like clients to automatically pick up needed
#   compiler requirements
# What you should find is that the "ccf-exports.cmake" file sets up an
# imported target for libccf, and sets the INTERFACE_COMPILE_FEATURES
# to those listed in 'THIS_REQUIRED_FEATURES'. That means that clients
# compiling with CMake and linking to the library will also require
# those features (and hence be compiled against the required standard).
# The issue of course is that other features like shared_ptr and so
# on cannot be added to this list

include(CMakePackageConfigHelpers)

# - Versioning File
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
  INSTALL_DESTINATION ${CMAKE_INSTALL_CMAKEDIR}/ccf
  PATH_VARS INSTALL_INCDIR
  )

install(EXPORT ccf-exports NAMESPACE "ccf::" DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf")
install(FILES ${PROJECT_BINARY_DIR}/InstallTreeFiles/ccf-config.cmake
  DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf"
  )

