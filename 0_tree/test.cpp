#include <vector>
#include <iostream>

int main()
{
  std::vector<int> a;
  a.reserve(20);
  a.resize(23);

  for (int i = 0; i < 23; ++i)
    a[i] = i;
  std::cout << a.back();
}
