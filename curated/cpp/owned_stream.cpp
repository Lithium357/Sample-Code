// C++20, standard library only. c++ -std=c++20 owned_stream.cpp -o check
// Move-only ownership of an already-open C stream. Borrowing get() never
// transfers ownership: callers must not fclose the result or keep it after
// reset/close/move assignment/destruction. release() DOES transfer ownership.
// Close is attempted exactly once even on failure; retrying fclose on an
// already-invalidated FILE* would be erroneous. This does not guarantee flush
// durability. The injected audit context must outlive all owners using it.
// Fixtures use std::tmpfile, never fixed names or credentials.
#include <cassert>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>

#ifdef NDEBUG
#error "This self-checking example requires assertions enabled"
#endif

struct CloseAudit {
  int attempts = 0;
  int failures = 0;
  bool report_failure = false;

  bool close(std::FILE *file) noexcept {
    ++attempts;
    const bool actual = std::fclose(file) == 0;
    // The fixture can report an error AFTER actually releasing the stream.
    // It models the ownership rule on failure without leaking a test resource.
    const bool result = actual && !report_failure;
    if (!result)
      ++failures;
    return result;
  }
};

class OwnedStream {
  std::FILE *file_ = nullptr;
  CloseAudit *audit_;

public:
  // Explicit adoption: file must be null or uniquely owned and still open.
  OwnedStream(std::FILE *file, CloseAudit &audit) noexcept
      : file_(file), audit_(&audit) {}
  OwnedStream(const OwnedStream &) = delete;
  OwnedStream &operator=(const OwnedStream &) = delete;
  OwnedStream(OwnedStream &&other) noexcept
      : file_(std::exchange(other.file_, nullptr)), audit_(other.audit_) {}
  OwnedStream &operator=(OwnedStream &&other) noexcept {
    if (this != &other) {
      close(); // use OUR old context, then transfer the incoming context
      audit_ = other.audit_;
      file_ = std::exchange(other.file_, nullptr);
    }
    return *this;
  }
  ~OwnedStream() noexcept { close(); }

  std::FILE *get() const noexcept { return file_; }
  explicit operator bool() const noexcept { return file_ != nullptr; }
  std::FILE *release() noexcept { return std::exchange(file_, nullptr); }
  bool close() noexcept {
    auto *old = std::exchange(file_, nullptr);
    return old == nullptr || audit_->close(old);
  }
  // Same pointer is a no-op. Otherwise adopt replacement even when closing the
  // old stream reports failure. false reports that close, not failed adoption.
  // replacement must be null or a distinct, uniquely owned open stream.
  bool reset(std::FILE *replacement = nullptr) noexcept {
    if (replacement == file_)
      return true;
    auto *old = std::exchange(file_, replacement);
    return old == nullptr || audit_->close(old);
  }
};

static_assert(!std::is_copy_constructible_v<OwnedStream>);
static_assert(!std::is_copy_assignable_v<OwnedStream>);
static_assert(std::is_nothrow_move_constructible_v<OwnedStream>);
static_assert(std::is_nothrow_move_assignable_v<OwnedStream>);
static_assert(std::is_nothrow_destructible_v<OwnedStream>);

std::FILE *open_fixture() {
  auto *stream = std::tmpfile();
  if (!stream)
    throw std::runtime_error("local tmpfile unavailable");
  return stream;
}

void verify_bytes(std::FILE *stream) {
  // Includes NUL and high-bit bytes; length is independent of strlen.
  const unsigned char bytes[] = {0, 65, 255, 10, 90};
  assert(std::fwrite(bytes, 1, sizeof bytes, stream) == sizeof bytes);
  // A positioning operation separates output and input on this update stream.
  assert(std::fseek(stream, 0, SEEK_SET) == 0);
  unsigned char readback[6] = {};
  assert(std::fread(readback, 1, sizeof readback, stream) == sizeof bytes);
  for (std::size_t i = 0; i < sizeof bytes; ++i)
    assert(readback[i] == bytes[i]);
  assert(std::feof(stream) != 0);
  std::clearerr(stream);
}

int main() {
  CloseAudit first, second;
  {
    OwnedStream empty(nullptr, first);
    assert(!empty && empty.get() == nullptr && empty.release() == nullptr);
    assert(empty.close() && empty.reset());
    assert(first.attempts == 0);

    OwnedStream original(open_fixture(), first);
    auto *borrowed = original.get();
    verify_bytes(borrowed);
    OwnedStream moved(std::move(original));
    assert(!original && moved.get() == borrowed && first.attempts == 0);
    // Moved-from objects remain reusable. Their context is still valid.
    assert(original.reset(open_fixture()));
    assert(original);

    OwnedStream target(open_fixture(), second);
    target = std::move(moved);
    assert(second.attempts == 1 && first.attempts == 0);
    assert(!moved && target.get() == borrowed);
    auto *same =
        &target; // exercise self-move without compiler diagnostic noise
    target = std::move(*same);
    assert(target.get() == borrowed && first.attempts == 0);
    assert(target.reset(target.get()));
    assert(first.attempts == 0);
    assert(target.close() && !target);
    assert(first.attempts == 1 && second.attempts == 1);
    assert(target.close());
    assert(first.attempts == 1);
  }
  assert(first.attempts == 2 && second.attempts == 1);

  CloseAudit released;
  {
    OwnedStream owner(open_fixture(), released);
    auto *raw = owner.release();
    assert(raw != nullptr && !owner && released.attempts == 0);
    OwnedStream adopter(raw, released);
    verify_bytes(adopter.get());
  }
  assert(released.attempts == 1);

  CloseAudit failed;
  failed.report_failure = true;
  {
    OwnedStream owner(open_fixture(), failed);
    assert(!owner.close() && !owner);
    assert(owner.close()); // never retry an invalidated stream
    assert(failed.attempts == 1 && failed.failures == 1);
    assert(owner.reset(open_fixture())); // empty -> adopted, no close attempt
    auto *replacement = open_fixture();
    assert(!owner.reset(replacement));
    assert(owner.get() == replacement);
    assert(failed.attempts == 2 && failed.failures == 2);
  }
  assert(failed.attempts == 3 && failed.failures == 3);

  // Move assignment must also transfer the incoming context when the old
  // close reports failure; the outgoing stream is still invalidated once.
  CloseAudit old, incoming;
  old.report_failure = true;
  {
    OwnedStream target(open_fixture(), old);
    OwnedStream source(open_fixture(), incoming);
    target = std::move(source);
    assert(old.attempts == 1 && old.failures == 1 && !source);
    assert(target.close());
  }
  assert(old.attempts == 1 && incoming.attempts == 1);

  CloseAudit unwind;
  try {
    OwnedStream scoped(open_fixture(), unwind);
    throw std::runtime_error("purposeful fixture exception");
  } catch (const std::runtime_error &error) {
    assert(std::string(error.what()) == "purposeful fixture exception");
  }
  assert(unwind.attempts == 1);
  CloseAudit relocated;
  {
    std::vector<OwnedStream> streams;
    streams.reserve(1);
    for (int i = 0; i < 20; ++i)
      // Adopt before vector allocation, so allocation failure cannot leak a
      // freshly opened raw stream in an argument to emplace_back.
      streams.push_back(OwnedStream(open_fixture(), relocated));
    assert(relocated.attempts ==
           0); // relocation must not close transferred files
    for (auto &stream : streams)
      assert(stream);
  }
  assert(relocated.attempts == 20);
  std::puts(
      "owned stream: bytes, moves, release, reset, errors and unwind passed");
}
