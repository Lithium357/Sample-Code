// Exact polynomial convolution modulo 998244353 with an iterative radix-2 NTT.
// C++20; primitive root 3; lengths up to 2^23 are mathematically supported.
// The public demo caps transforms at 2^18 to bound allocations and runtime.
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <random>
#include <stdexcept>
#include <vector>

using Word = std::uint32_t;
using Wide = std::uint64_t;
constexpr Word modulus = 998244353;
constexpr std::size_t maximum_transform = 1u << 18;
Word power(Word a, Word exponent) {
  Word result = 1;
  while (exponent) {
    if (exponent & 1u)
      result = static_cast<Word>(Wide(result) * a % modulus);
    a = static_cast<Word>(Wide(a) * a % modulus);
    exponent >>= 1;
  }
  return result;
}
void transform(std::vector<Word> &values, bool inverse) {
  const auto n = values.size();
  if (n == 0 || (n & (n - 1)) != 0 || n > maximum_transform)
    throw std::invalid_argument("invalid transform length");
  for (auto value : values)
    if (value >= modulus)
      throw std::invalid_argument("noncanonical coefficient");
  for (std::size_t i = 1, j = 0; i < n; ++i) {
    auto bit = n >> 1;
    for (; j & bit; bit >>= 1)
      j ^= bit;
    j ^= bit;
    if (i < j)
      std::swap(values[i], values[j]);
  }
  for (std::size_t length = 2; length <= n; length *= 2) {
    Word root = power(3, static_cast<Word>((modulus - 1) / length));
    if (inverse)
      root = power(root, modulus - 2);
    for (std::size_t start = 0; start < n; start += length) {
      Word factor = 1;
      for (std::size_t j = 0; j < length / 2; ++j) {
        Word left = values[start + j];
        Word right = static_cast<Word>(Wide(values[start + j + length / 2]) *
                                       factor % modulus);
        Word sum = left + right;
        if (sum >= modulus)
          sum -= modulus;
        Word difference = left >= right ? left - right : left + modulus - right;
        values[start + j] = sum;
        values[start + j + length / 2] = difference;
        factor = static_cast<Word>(Wide(factor) * root % modulus);
      }
    }
  }
  if (inverse) {
    Word scale = power(static_cast<Word>(n), modulus - 2);
    for (auto &value : values)
      value = static_cast<Word>(Wide(value) * scale % modulus);
  }
}
std::vector<Word> convolution(const std::vector<Word> &a,
                              const std::vector<Word> &b) {
  if (a.empty() || b.empty())
    return {};
  if (a.size() > maximum_transform || b.size() > maximum_transform ||
      a.size() + b.size() - 1 > maximum_transform)
    throw std::length_error("convolution too large");
  const auto result_size = a.size() + b.size() - 1;
  std::size_t size = 1;
  while (size < result_size)
    size *= 2;
  std::vector<Word> left = a, right = b;
  left.resize(size);
  right.resize(size);
  transform(left, false);
  transform(right, false);
  for (std::size_t i = 0; i < size; ++i)
    left[i] = static_cast<Word>(Wide(left[i]) * right[i] % modulus);
  transform(left, true);
  left.resize(result_size);
  return left;
}
std::vector<Word> naive(const std::vector<Word> &a,
                        const std::vector<Word> &b) {
  if (a.empty() || b.empty())
    return {};
  std::vector<Word> result(a.size() + b.size() - 1);
  for (std::size_t i = 0; i < a.size(); ++i)
    for (std::size_t j = 0; j < b.size(); ++j)
      result[i + j] =
          static_cast<Word>((result[i + j] + Wide(a[i]) * b[j]) % modulus);
  return result;
}
int main() {
  assert((convolution({1, 2, 3}, {4, 5}) == std::vector<Word>{4, 13, 22, 15}));
  assert(convolution({}, {1}).empty());
  std::mt19937 random(109);
  for (std::size_t trial = 0; trial < 400; ++trial) {
    std::vector<Word> a(trial % 41), b((trial * 7) % 43);
    for (auto &value : a)
      value = random() % modulus;
    for (auto &value : b)
      value = random() % modulus;
    assert(convolution(a, b) == naive(a, b));
  }
  for (std::size_t size = 1; size <= 4096; size *= 2) {
    std::vector<Word> values(size);
    for (auto &value : values)
      value = random() % modulus;
    auto original = values;
    transform(values, false);
    transform(values, true);
    assert(values == original);
  }
  bool rejected = false;
  try {
    std::vector<Word> invalid(3);
    transform(invalid, false);
  } catch (const std::invalid_argument &) {
    rejected = true;
  }
  assert(rejected);
  rejected = false;
  try {
    (void)convolution({modulus}, {1});
  } catch (const std::invalid_argument &) {
    rejected = true;
  }
  assert(rejected);
  std::cout << "NTT: 400 quadratic-oracle convolutions, inverse transforms and "
               "invalid inputs passed\n";
}
