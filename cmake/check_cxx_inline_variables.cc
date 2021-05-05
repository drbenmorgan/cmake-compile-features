// Check for inline variable support
// - https://en.cppreference.com/w/cpp/language/inline

#include <string>

namespace foo {
  inline constexpr int bar = 41;
}

int main() {
  int baz = foo::bar + 1;
}