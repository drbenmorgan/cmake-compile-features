// Check that C++ Structured Bindings are supported
// - https://en.cppreference.com/w/cpp/language/structured_binding

int main() {
  // Array binding
  int a[2] = {42, 24};
  auto [x, y] = a;
}