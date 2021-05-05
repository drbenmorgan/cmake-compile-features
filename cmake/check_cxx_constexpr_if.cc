// Check for constexpr if support
// - https://en.cppreference.com/w/cpp/language/if

#include <iostream>

int main() {
  if constexpr ( 42 > 24 ) return 0;
  else return 1;
}