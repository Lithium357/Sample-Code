// Owning move-only C++20 generator, lazy execution, exception propagation and
// RAII cleanup on early termination. No reference-yields or borrowed frames.
// c++ -std=c++20 coroutine_generator.cpp -o generator && ./generator
#include <cassert>
#include <concepts>
#include <coroutine>
#include <exception>
#include <iostream>
#include <iterator>
#include <memory>
#include <optional>
#include <stdexcept>
#include <utility>
#include <vector>

template <class T> class Generator {
public:
  struct promise_type;
  using Handle = std::coroutine_handle<promise_type>;
  struct promise_type {
    std::optional<T> current;
    std::exception_ptr failure;
    Generator get_return_object() {
      return Generator(Handle::from_promise(*this));
    }
    std::suspend_always initial_suspend() noexcept { return {}; }
    std::suspend_always final_suspend() noexcept { return {}; }
    std::suspend_always yield_value(T value) {
      current.emplace(std::move(value));
      return {};
    }
    void return_void() noexcept {}
    void unhandled_exception() noexcept { failure = std::current_exception(); }
  };
  class Iterator {
    Handle handle;
    void advance() {
      handle.promise().current.reset();
      handle.resume();
      if (handle.done() && handle.promise().failure)
        std::rethrow_exception(handle.promise().failure);
    }

  public:
    using value_type = T;
    using difference_type = std::ptrdiff_t;
    using iterator_concept = std::input_iterator_tag;
    Iterator() = default;
    explicit Iterator(Handle h) : handle(h) {}
    const T &operator*() const { return *handle.promise().current; }
    Iterator &operator++() {
      advance();
      return *this;
    }
    void operator++(int) { advance(); }
    bool operator==(std::default_sentinel_t) const {
      return !handle || handle.done();
    }
  };

private:
  Handle handle{};
  bool started = false;
  explicit Generator(Handle h) : handle(h) {}

public:
  Generator(const Generator &) = delete;
  Generator &operator=(const Generator &) = delete;
  Generator(Generator &&other) noexcept
      : handle(std::exchange(other.handle, {})), started(other.started) {}
  Generator &operator=(Generator &&other) noexcept {
    if (this != &other) {
      if (handle)
        handle.destroy();
      handle = std::exchange(other.handle, {});
      started = other.started;
    }
    return *this;
  }
  ~Generator() {
    if (handle)
      handle.destroy();
  }
  Iterator begin() {
    if (!handle)
      throw std::logic_error("moved-from generator");
    if (started)
      throw std::logic_error("generator is single-pass");
    started = true;
    handle.resume();
    if (handle.done() && handle.promise().failure)
      std::rethrow_exception(handle.promise().failure);
    return Iterator(handle);
  }
  std::default_sentinel_t end() const noexcept { return {}; }
};
static_assert(std::input_iterator<Generator<int>::Iterator>);

struct Lifetime {
  int *count;
  explicit Lifetime(int &value) : count(&value) { ++*count; }
  ~Lifetime() { --*count; }
};
Generator<int> counted(int &live, int &visited) {
  Lifetime lifetime(live);
  for (int i = 0; i < 10; ++i) {
    ++visited;
    co_yield i;
  }
}
Generator<int> failing() {
  co_yield 7;
  throw std::runtime_error("generator failure");
}
Generator<int> immediately_failing() {
  throw std::runtime_error("early failure");
  co_return;
}
Generator<int> empty() { co_return; }
Generator<std::unique_ptr<int>> owned() {
  co_yield std::make_unique<int>(11);
  co_yield std::make_unique<int>(22);
}
Generator<int> squares(Generator<int> input) {
  for (int value : input)
    co_yield value *value;
}
int main() {
  int live = 0, visited = 0;
  {
    auto source = counted(live, visited);
    assert(live == 0 && visited == 0);
    auto moved = std::move(source);
    for (int value : moved) {
      assert(value == 0 && live == 1);
      break;
    }
    assert(visited == 1 &&
           live == 1); // Suspended frame remains owned until destruction.
  }
  assert(live == 0);
  std::vector<int> actual;
  for (int value : squares(counted(live, visited)))
    actual.push_back(value);
  assert(actual.size() == 10 && actual[9] == 81 && live == 0);
  auto no_values = empty();
  assert(no_values.begin() == no_values.end());
  bool caught = false;
  try {
    for (int value : failing()) {
      assert(value == 7);
    }
  } catch (const std::runtime_error &) {
    caught = true;
  }
  assert(caught);
  caught = false;
  try {
    auto bad = immediately_failing();
    (void)bad.begin();
  } catch (const std::runtime_error &) {
    caught = true;
  }
  assert(caught);
  int total = 0;
  for (const auto &pointer : owned())
    total += *pointer;
  assert(total == 33);
  auto once = counted(live, visited);
  auto iterator = once.begin();
  (void)iterator;
  caught = false;
  try {
    (void)once.begin();
  } catch (const std::logic_error &) {
    caught = true;
  }
  assert(caught);
  std::cout << "Coroutine generator: lazy frames, move-only values, "
               "single-pass rules, exceptions and RAII passed\n";
}
