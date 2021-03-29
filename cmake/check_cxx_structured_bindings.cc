// Check that C++ Structured Bindings are supported
// - https://en.cppreference.com/w/cpp/language/structured_binding

struct MyStruct {
  int a = 42;
  double b = 3.14;
};

int main() {
  // Array binding
  int a[2] = {42, 24};
  auto [x, y] = a;

  // Struct binding
  auto [n, m] = MyStruct{};
}