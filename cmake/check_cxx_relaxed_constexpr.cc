// Check C++14's relaxed constexpr requirements work
// - https://en.cppreference.com/w/cpp/language/constexpr

// Can now declare local variables, use loop/conditionals
constexpr int my_strcmp( const char* str1, const char* str2 ) {
  int i = 0;
  for( ; str1[i] && str2[i] && str1[i] == str2[i]; ++i )
  {}
  if( str1[i] == str2[i] ) return 0;
  if( str1[i] < str2[i] ) return -1;
  return 1;
}

int main() {
  const char* a = "foobar";
  const char* b = "foobaz";

  return my_strcmp(a, b);
}