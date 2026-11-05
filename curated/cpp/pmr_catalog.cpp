// C++20: transactional replacement with polymorphic allocators.
// A nonnull memory_resource must outlive Catalog. No concurrent access is
// supported. Names are byte strings (including NUL), not a Unicode/filename
// validator. Replacement validates first, builds with the SAME allocator, then
// commits by swapping. Views into the old catalog may be used as input to
// replacement.
#include <array>
#include <cassert>
#ifdef NDEBUG
#error "This executable fixture requires assertions enabled; NDEBUG is unsupported"
#endif
#include <cstddef>
#include <iostream>
#include <limits>
#include <memory_resource>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

class Catalog {
  std::pmr::vector<std::pmr::string> names;

public:
  explicit Catalog(std::pmr::memory_resource *resource) : names(resource) {}
  std::string_view at(std::size_t i) const { return names.at(i); }
  std::vector<std::string> snapshot() const {
    std::vector<std::string> result;
    for (const auto &name : names)
      result.emplace_back(name);
    return result;
  }
  void replace(std::span<const std::string_view> input) {
    if (input.size() > 32)
      throw std::invalid_argument("too many names");
    for (std::size_t i = 0; i < input.size(); ++i) {
      if (input[i].empty() || input[i].size() > 128)
        throw std::invalid_argument("name length");
      for (std::size_t j = 0; j < i; ++j)
        if (input[i] == input[j])
          throw std::invalid_argument("duplicate name");
    }
    std::pmr::vector<std::pmr::string> pending(names.get_allocator());
    pending.reserve(input.size());
    // allocator-aware vector construction supplies each string's allocator.
    for (auto name : input)
      pending.emplace_back(name);
    names.swap(pending); // equal resource identity; no allocator mismatch
  }
};

class FailingResource final : public std::pmr::memory_resource {
  std::size_t fail_at = std::numeric_limits<std::size_t>::max();
  void *do_allocate(std::size_t bytes, std::size_t alignment) override {
    if (attempts++ == fail_at)
      throw std::bad_alloc();
    void *pointer = std::pmr::new_delete_resource()->allocate(bytes, alignment);
    ++blocks;
    live_bytes += bytes;
    return pointer;
  }
  void do_deallocate(void *pointer, std::size_t bytes,
                     std::size_t alignment) override {
    assert(blocks > 0 && live_bytes >= bytes);
    --blocks;
    live_bytes -= bytes;
    std::pmr::new_delete_resource()->deallocate(pointer, bytes, alignment);
  }
  bool
  do_is_equal(const std::pmr::memory_resource &other) const noexcept override {
    return this == &other;
  }

public:
  std::size_t attempts = 0, blocks = 0, live_bytes = 0;
  void fail_on(std::size_t ordinal) {
    attempts = 0;
    fail_at = ordinal;
  }
  void allow() { fail_on(std::numeric_limits<std::size_t>::max()); }
  ~FailingResource() override { assert(blocks == 0 && live_bytes == 0); }
};

int main() {
  const std::string old_a(50, 'a'), old_b(60, 'b');
  const std::string new_a(80, 'x'), new_b(90, 'y'), new_c(100, 'z');
  const std::array<std::string_view, 2> seed{old_a, old_b};
  const std::array<std::string_view, 3> desired{new_a, new_b, new_c};
  std::size_t failures = 0;
  bool success = false;
  // Sweep allocation failures until an entire operation can complete. Expected
  // contents are fixed test data; observing allocation count only sizes the
  // sweep.
  for (std::size_t ordinal = 0; ordinal < 64 && !success; ++ordinal) {
    FailingResource resource;
    {
      Catalog catalog(&resource);
      catalog.replace(seed);
      const auto baseline = catalog.snapshot();
      const auto bytes = resource.live_bytes, blocks = resource.blocks;
      resource.fail_on(ordinal);
      try {
        catalog.replace(desired);
        assert((catalog.snapshot() ==
                std::vector<std::string>{new_a, new_b, new_c}));
        success = true;
      } catch (const std::bad_alloc &) {
        ++failures;
        assert(catalog.snapshot() == baseline);
        assert(resource.live_bytes == bytes && resource.blocks == blocks);
      }
    }
    assert(resource.live_bytes == 0 && resource.blocks == 0);
  }
  assert(success && failures >= 4); // vector plus three non-SSO strings
  FailingResource resource;
  {
    Catalog catalog(&resource);
    catalog.replace(seed);
    const std::array<std::string_view, 2> aliases{catalog.at(1), catalog.at(0)};
    catalog.replace(aliases);
    assert((catalog.snapshot() == std::vector<std::string>{old_b, old_a}));
    const auto baseline = catalog.snapshot();
    const std::string too_long(129, 'q');
    for (const auto &invalid : std::vector<std::vector<std::string_view>>{
             {""},
             {"same", "same"},
             {too_long},
             std::vector<std::string_view>(33, "x")}) {
      resource.fail_on(0); // invalid inputs must be rejected before allocation
      bool rejected = false;
      try {
        catalog.replace(invalid);
      } catch (const std::invalid_argument &) {
        rejected = true;
      }
      assert(rejected && resource.attempts == 0 &&
             catalog.snapshot() == baseline);
    }
    resource.allow();
    const std::string maximum(128, 'm');
    const std::array<std::string_view, 2> binary{maximum,
                                                 std::string_view("a\0b", 3)};
    catalog.replace(binary);
    assert((catalog.snapshot() ==
            std::vector<std::string>{maximum, std::string("a\0b", 3)}));
    std::vector<std::string> owned;
    for (int i = 0; i < 32; ++i)
      owned.push_back("name " + std::to_string(i));
    std::vector<std::string_view> views;
    for (const auto &name : owned)
      views.push_back(name);
    catalog.replace(views);
    assert(catalog.snapshot() == owned);
    catalog.replace(std::span<const std::string_view>{});
    assert(catalog.snapshot().empty() && resource.live_bytes == 0);
  }
  std::cout << "PMR catalog: failure sweep, unchanged state, complete cleanup, "
               "aliased views, byte strings and exact limits passed\n";
}
