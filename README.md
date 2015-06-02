# cmake-compile-features
Study of CMake compile features

# Requirements
- CMake 3.2 or better
  - Needed to support latest AppleClang, MSVC.
  - Note that Intel support may be lacking at the moment (see below)
- GNU, Clang, Xcode (AppleClang) or MSVC compilers
- Suitable buildtool (ideally command line, so output/flags can be seen)

# Example build on Unix
```
$ ls
CMakeLists.txt    LICENSE           README.md         basic-program.cpp
$ mkdir build
$ cd build
$ cmake ..
... output should report info about compiler, C++ features known to
... CMake, and C++ features supported by the compiler
$ make
... Compilation commands should contain correct "-std=c++XY" line
```

# Noted issues
## Intel support
Appears that there isn't support for compile features of Intel compiler.
Need to find out if an extension can be provided, or whether we have
to wait for upstream CMake to support this.

## Compiler vs Library Features
Difference between *compiler* features and *library* features. CMake's
compile features deals with the former. Library features are things like

- Smart pointers
- Hashed containers
- Random numbers
- Concurrency

Certainly need compile checks for these - but these are easy to write.

## `thread_local` in Xcode (AppleClang)
Apple's Clang that comes with Xcode doesn't support this at present.
There's [a discussion on StackOverflow}(http://stackoverflow.com/questions/28094794/why-does-apple-clang-disallow-c11-thread-local-when-official-clang-supports). An upstream issue with Apple, so have to await their implementation of this. Not yet clear if this affects libc++ concurrency support.

