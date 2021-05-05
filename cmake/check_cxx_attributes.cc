// Check availability of attributes
// - https://en.cppreference.com/w/cpp/language/attributes

[[deprecated]]
void foo() {}

[[nodiscard]]
int bar() {return 42;}

[[maybe_unused]]
int baz() {return 24;}

int main() {}