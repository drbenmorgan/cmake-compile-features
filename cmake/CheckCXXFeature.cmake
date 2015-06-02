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

#-----------------------------------------------------------------------
# Check FEATURE_NAME, setting RESULT_VAR to TRUE if feature is present

function(check_cxx_feature FEATURE_NAME RESULT_VAR)
endfunction()

message(STATUS "${CMAKE_CXX_SOURCE_FILE_EXTENSIONS}")
