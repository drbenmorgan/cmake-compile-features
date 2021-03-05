// Check that preprocessor supports __has_include:
// - https://en.cppreference.com/w/cpp/preprocessor/include

#if __has_include(<iostream>)
#include <iostream>
#endif

int main() {}