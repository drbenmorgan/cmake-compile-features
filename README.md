# cmake-compile-features
Study of CMake compile features

# Requirements
- CMake 3.3 or better
  - Needed to support latest AppleClang, MSVC.
   - MSVC2015 needs 3.3 otherwise constexpr support is lacking
   - Intel features included by project, not yet in CMake.
- GNU, Clang, Xcode (AppleClang) or MSVC compilers
- Suitable buildtool (ideally command line, so output/flags can be seen)

# Example build on Unix
```
$ ls
CMakeLists.txt  README.md       ccf-program.cpp
LICENSE         ccf             cmake
$ cd build
$ cmake ..
... output should report info about compiler, C++ features known to
... CMake, and C++ features supported by the compiler
$ cmake --build .
... Compilation commands should contain correct "-std=c++XY" line
```

# Comments
## Checking for C++ Support
Important to note the difference between *compiler* (syntax) features and
*standard library* (implementation) features. CMake's compile features
functionality deals with the former, e.g. the compiler understands the
`auto` keyword. At link time the program is linked to the actual C++
Standard Library implementation which may be different from any supplied
by the compiler vendor. For example, the Intel compiler may link to
the GNU implementation of the Standard Library, Clang may link to the
GNU or LLVM implementations.

Standard Library features are actual objects/functions such as

- Smart pointers
- Hashed containers
- Random numbers
- Concurrency

Checks for these are implemented using a wrapper around CMake's
`try_compile` functionality, with success/failure being recorded in a
CMake variable. That can subsequently be used to fail the configuration
or provide workarounds as required. Implementation may still need some
work to both fully exercise requirements on the objects and to make
the tests transparent across newer standards.

This `try_compile` method could also perform syntax checks if required.
However, it does not handle automatically adding any needed compiler flags
nor propgating requirements to clients.

## Forwarding C++ Support
If we are building a library which is compiled with a given C++ standard,
then clients linking to this library should (mostly) compile their code
against the same (or compatible) standard. If CMake is used, then compile
features help to transitively pass down the requirements. For example

```cmake
add_library(foo foo.hpp foo.cpp)
target_compile_features(foo PUBLIC cxx_constexpr)
# Effectively results in "g++ -std+c++11 foo.cpp"
...

add_executable(bar bar.cpp)
target_link_libraries(bar foo)
# Linking transitevely propgates compile features, so effectively
# results in "g++ -std=c++11 bar.cpp -lfoo"
```

Compile features therefore propagate over CMake targets, including
via exported targets (which create imported targets that clients
actually link against).

## C++ Standard Library Workarounds
Illustrated by the `std::make_unique` case, where a useful bit of functionality
didn't quite make it into a given standard (C++11) but can be implemented in
that standard. The CMake script has the functionality to test for the presence
and working of something in the Standard Library implementation in use, and
sets boolean (CMake) variables to indicate its presence or otherwise.
Here, we export this variable using `configure_file` to set a `#cmakedefine`
symbol in a header. That symbol then protects a local implementation of that
feature.

In this project, the exemplar `std::make_unique` is shown so that:

- C++11 systems can use `std::make_unique`
- C++14 systems that don't provide a `std::make_unique` implementation can use it
- There won't be a clash if the Standard Library provides an implementation

See the template file [`ccf/detail/ccf_stdlib_support.hpp.in`](ccf/detail/ccf_stdlib_support.hpp.in) in the source directory, plus the generated header
`ccf/detail/ccf_stdlib_support.hpp` in the build directory.


# Noted issues
## Intel support
Appears that there isn't support for compile features or header detection
on the Intel compiler. Need to find out if an extension can be provided
(yes, it can, see below), or whether we have to wait for upstream CMake
to support this (no, but this is the ideal case, and should submit patch!).

The list(s) of compile features can be set after a project call, and
they will be recognized by targets using them as supported, e.g.

```cmake
if(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
  message(STATUS "CMAKE_COMPILER_ID matches 'Intel'")
  # No version checking yet, that's needed for full implementation
  set(CMAKE_CXX11_COMPILE_FEATURES cxx_auto_type cxx_range_for)
  set(CMAKE_CXX_COMPILE_FEATURES ${CMAKE_CXX11_COMPILE_FEATURES})
  set(CMAKE_CXX11_STANDARD_COMPILE_OPTION "-std=c++11")
  set(CMAKE_CXX11_EXTENSION_COMPILE_OPTION "-std=c++11")
  set(CMAKE_CXX98_STANDARD_COMPILE_OPTION  "-std=c++11")
  set(CMAKE_CXX98_EXTENSION_COMPILE_OPTION "-std=c++98")

  # This is the critical variable, there must be a default when the compiler
  # has the notion of standards
  set(CMAKE_CXX_STANDARD_DEFAULT "98")
endif()

...

add_executable(myprogram myprogram.cpp)
target_compile_features(myprogram PRIVATE cxx_auto_type)
```

The critical setting is the `CMAKE_CXX_STANDARD_DEFAULT` variable. This is
required for compilers that have the notion of setting the standard.

Intel also has the issue (as with Non-Apple/BSD Clang) of Standard Library
selection, though compile features should only refer to things the compiler
can generate code for. Needs further investigation, e.g. to use CMake's
compiler feature detection mechanism to check stdlib impl/version as
part of feature checking. Or could use separate stdlib detection.


## `thread_local` in Xcode (AppleClang)
Apple's Clang that comes with Xcode doesn't support this at present.
There's [a discussion on StackOverflow}(http://stackoverflow.com/questions/28094794/why-does-apple-clang-disallow-c11-thread-local-when-official-clang-supports). An upstream issue with Apple, so have to await their implementation of this. Not yet clear if this affects libc++ concurrency support.

It's possible to provide workarounds here via the [compiler detection
header part of CMake](https://cmake.org/cmake/help/v3.3/module/WriteCompilerDetectionHeader.html) (see the `ccf/detail/ccf_compiler_support.hpp` header
under the build directory). This is also the general mechanism for
providing workarounds for syntax where it's possible

## Compiling against newer C++ Standards (14, 17, ...)
The use case here is consuming projects that require use of a newer
C++ standard than currently required by this project. For example,
this project only uses features of C++11, but a consuming project
uses features of C++14. It's an issue because the ABI of the
Standard Library may be incompatible between objects compiled
against different standards. This was highlighted by early adopters of
C++11 making using of the experimental and unstable ABI in GCC4.

Whilst C++'s ABI *should* stabilize in coming standard, allowances should
be made for the same issue arising as C++17 is formalized. Forcing use
of a particular standard can be done via setting the variables
`CMAKE_CXX_STANDARD` and `CMAKE_CXX_STANDARD_REQUIRED` prior to
target declaration. These are used to initialize the `CXX_STANDARD` property of targets, and this can co-exist with compile features as the
newest standard required will be used. For example, a target with
`CXX_STANDARD' set to '14' and only using C++11 compile features
would result in the target's sources being compiled against C++14 (and vice versa).

Unlike compile features however, the `CXX_STANDARD` property of targets
is *not* exported for use by consuming targets. This means that
consuming targets would only compile against the standard required by
the compile features of the library, even if this standard is older
than the one actually used to compile the library against. Consequently
an ABI incompatibility would occur if all objects must have been
compiled/linked with the same standard.

There are several potential ways to resolve this. Whilst the `CXX_STANDARD`
and `CXX_STANDARD_REQUIRED` target properties are not directly exported,
it may be possible to set them manually on the imported targets created by
the project's cmake config module. Initial tests suggest that this isn't
passed down to consuming targets though, so would not be of great use.

Another possibility is to use the `INTERFACE_COMPILE_OPTIONS` target property to pass down any relevant flags to the
compiler, but this requires some work with generator expressions to
choose between compilers.

The final option is to artifically add a single C++14 compile feature to the
required list if the compiler support C++14. This would work, but the single
option would need to be supported across all compilers.

- Intel : `cxx_binary_literals` seems reasonable from 11-14, auto return types from 15
- MSVC : auto/decltype(auto) return types or init captures from VS14, binary literals from VS15
- GNU : binary literals from 4.9, auto return type from 4.8
- Clang : binary literals from 2.9, decltype(auto) from 3.3, and 3.3 is minimum to be C++11 complete.

So using the `cxx_decltype_auto` feature would probably be sufficient.

