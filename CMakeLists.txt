# Project to demo CMake compile features for C++ standard

# Want to support gcc 4.9, Clang 3.5/6, Intel 15 and VS2015
# NB: Still to be investigated how to support compile features for
# compiler where CMake does not yet provide a '-FeatureTests' file.
cmake_minimum_required(VERSION 3.2)
project(cmake-compile-features)

# - Always verbose so we can see compile flags
set(CMAKE_VERBOSE_MAKEFILE ON)

# - Enumerated option to allow C++ Standard selection
include(cmake/EnumeratedOption.cmake)

# - Include modules for helping to check C++ stdlib features
include(cmake/CheckCXXFeature.cmake)
include(cmake/CheckCXXStandardLibrary.cmake)


#-----------------------------------------------------------------------
# Compiler Info
# - Print, for info, detected Compiler and Version
message(STATUS "CXX compiler ID: '${CMAKE_CXX_COMPILER_ID}'")
message(STATUS "CXX compiler Version: '${CMAKE_CXX_COMPILER_VERSION}'")

#-----------------------------------------------------------------------
# C++ Standard Selection - 11, 14 or 17
# Not used yet - the primary use case for this over compile features
# is for clients to compile the project against a newer standard.
# That's sometimes needed to ensure ABI compatibility (e.g. libstdc++
# had/has different ABIs for C++98/11). The main issue here is
# any cases of non-forward compatibility (e.g. 17 removes something in
# the 11 standard)
# In a production environment it would be an advanced option.
# TODO: work out how to marry this with compile features - e.g.
# can use CMAKE_CXX_STANDARD, CMAKE_CXX_STANDARD_REQUIRED, but these
# are not exported as target properties. May need to use individual
# 'CMAKE_CXX<STD>_COMPILE_FEATURES', e.g. append all available 14 features
# for the compiler, but this might be hacky...
# TODO: Really requires a proper understanding of ABI differences in
# standard libraries and across standards.
enum_option(BUILD_CXX_STANDARD
  DOC "C++ Standard to compile against"
  VALUES 11 14 17
  CASE_INSENSITIVE
  )

#-----------------------------------------------------------------------
# Compiler features
# - Do NOT want vendor extensions (e.g. no --std=gnu++11)
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

# - whereas CMAKE_CXX<std>_COMPILE_FEATURES should list those the compiler
#   actually supports
message(STATUS "List of supported CXX11 features")
foreach(_f ${CMAKE_CXX11_COMPILE_FEATURES})
  message("  ${_f}")
endforeach()
message(STATUS "List of supported CXX14 features")
foreach(_f ${CMAKE_CXX14_COMPILE_FEATURES})
  message("  ${_f}")
endforeach()
#-----------------------------------------------------------------------
# Based on Ivana's document, list absolute required features
# These are CMake compile features
set(CCF_REQUIRED_FEATURES
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
  # Smart pointers are a library implementation feature
  cxx_lambdas
  # Hashed containers are a library implementation feature
  # Random numbers are a library implementation feature?
  # - Thread local? Yes, though on AppleClang platforms, see this:
  #http://stackoverflow.com/questions/28094794/why-does-apple-clang-disallow-c11-thread-local-when-official-clang-supports
  # An example of where a workaround is needed
  # Rest of concurrency a library implementation feature
  )

# - Can also write a compiler detection header. This is useful
# for providing workarounds such as for the thread_local case above
# Only issue here is that it doesn't at support Intel yet...
# Note that this project doesn't use the header, it's purely here
# to show how it's generated.
include(WriteCompilerDetectionHeader)
write_compiler_detection_header(
  FILE "${CMAKE_CURRENT_BINARY_DIR}/ccf_compiler_detection.hpp"
  PREFIX CCF
  COMPILERS GNU Clang AppleClang MSVC
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
# At present, we force the use of C++11, so, this doesn't handle the use
# case of using a newer standard to compile against. This ties in
# with the other issues of how to select the standard.
check_cxx11_feature("cxx_memory_shared_ptr" HAS_CXX_MEMORY_SHARED_PTR)
check_cxx11_feature("cxx_memory_unique_ptr" HAS_CXX_MEMORY_UNIQUE_PTR)
check_cxx11_feature("cxx_memory_weak_ptr" HAS_CXX_MEMORY_WEAK_PTR)
check_cxx11_feature("cxx_memory_make_unique" HAS_CXX_MEMORY_MAKE_UNIQUE)

#-----------------------------------------------------------------------
# Compile this project's library using compile features
add_library(ccf-features SHARED ccf.hpp ccf.cpp)

#... with the required compile features
# PUBLIC means that clients of libccf will inherit the features of ccf
# and hence be compiled with the appropriate flags
target_compile_features(ccf-features PUBLIC ${CCF_REQUIRED_FEATURES})

#-----------------------------------------------------------------------
# And the equivalent with CXX_STANDARD
add_library(ccf-standard SHARED ccf.hpp ccf.cpp)
set_target_properties(ccf-standard
  PROPERTIES
   CXX_STANDARD ${BUILD_CXX_STANDARD}
   CXX_STANDARD_REQUIRED TRUE
   # NB if we *also* use COMPILE_FEATURES, then the newest standard takes
   # precedence
   COMPILE_FEATURES cxx_user_literals
  )


#-----------------------------------------------------------------------
# Now the project program (equally, this could be a client program)
add_executable(ccf-program ccf-program.cpp)

#... and link it to the library. Even though we haven't see compile_features
# for the program, it "inherits" the PUBLIC ones from the target.
# In consequence, it's compiled with the appropriate flags!
target_link_libraries(ccf-program ccf-features)

#-----------------------------------------------------------------------
# Install...
include(GNUInstallDirs)
set(CMAKE_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake")

install(TARGETS ccf-features ccf-standard ccf-program EXPORT ccf-exports DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES ccf.hpp DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

#-----------------------------------------------------------------------
# Support files
# - Here, we would like clients to automatically pick up needed
#   compiler requirements
# What you should find is that the "ccf-exports.cmake" file sets up an
# imported target for libccf, and sets the INTERFACE_COMPILE_FEATURES
# to those listed in 'CCF_REQUIRED_FEATURES'. That means that clients
# compiling with CMake and linking to the library will also require
# those features (and hence be compiled against the required standard).
# It's basically the same behaviour seen above with ccf-program
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
  INSTALL_DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf"
  PATH_VARS INSTALL_INCDIR
  )

install(EXPORT ccf-exports NAMESPACE "ccf::" DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf")
install(FILES ${PROJECT_BINARY_DIR}/InstallTreeFiles/ccf-config.cmake
  DESTINATION "${CMAKE_INSTALL_CMAKEDIR}/ccf"
  )

