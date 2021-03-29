// Check init statement in if/switch supported
// - https://en.cppreference.com/w/cpp/language/if
// - https://en.cppreference.com/w/cpp/language/switch

int main() {
  if(int x = 42; x > 42) {
    x++;
  }

  switch (int y = 24; y) {
    case 24: y++; break;
    default:  y--; break;
  }
}