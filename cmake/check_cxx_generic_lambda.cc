// Check for generic lambda support
// - https://en.cppreference.com/w/cpp/language/lambda

#include <vector>
#include <algorithm>

int main() {
  std::vector<double> w = { 1.0, 2.0, 4.0, 8.0};

  std::sort( std::begin(w), std::end(w),
    [](const auto& a, const auto& b) { return a<b; });

  auto size = [](const auto& x) { return x.size(); };

  return size(w);
}