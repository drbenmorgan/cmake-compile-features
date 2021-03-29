// Check for presence of make_unique in memory
// - https://en.cppreference.com/w/cpp/memory/unique_ptr/make_unique
#include <memory>

int main()
{
  std::unique_ptr<int> foo = std::make_unique<int>(42);

  return ((*foo) == 42) ? 0 : 1;
}
