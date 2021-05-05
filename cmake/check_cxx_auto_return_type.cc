// Check that auto return type deduction works
// - https://en.cppreference.com/w/cpp/language/auto

#include <utility>

// Return type should be type of operator+(T, U)
template <typename T, typename U>
auto add(T a, U b) {
  return a + b;
}

int main() {
  auto b = add(1, 1.2);      // type of b is double
  static_assert(std::is_same_v<decltype(b), double>);
}
