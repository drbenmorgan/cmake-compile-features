// - Which Standard C++ library are we using?
// NB: Can probably replace this with Boost's Predef system, though
// requires Boost or a bcp import.
//
// For cross-compiling, *might* be able to use pragma/message to
// generate output from the preprocessor, but this can be awkward.
// Note the need to use stringization to expand other preprocessor
// symbols:
//
// #define PPSTRINGIZE(x) PPSTRINGIZE2(x)
// #define PPSTRINGIZE2(x) #x
//
// and that messaging facilities in the preprocessor change, e.g.
// "warning", "pragma message" etc. Some, like "warning" in GCC,
// don't expand their macro arguments either!
//

//
// Copyright (c) 2014, Ben Morgan <bmorgan.warwick@gmail.com>
//
// Distributed under the OSI-approved BSD 3-Clause License (the "License");
// see accompanying file License.txt for details.
//
// This software is distributed WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the License for more information.

#include <iostream>

int main() {
#if defined(_LIBCPP_VERSION)
  std::cout << "libc++;" << _LIBCPP_VERSION;
#elif defined(__GLIBCXX__)
  std::cout << "libstdc++;" << __GLIBCXX__;

// - And so on for any others...
#else
  return 1;
#endif
  return 0;
}
