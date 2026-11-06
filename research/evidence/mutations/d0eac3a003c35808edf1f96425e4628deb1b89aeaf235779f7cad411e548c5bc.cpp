// C++20, std only. c++ -std=c++20 generational_pool.cpp -o pool && ./pool
// Fixed-capacity, address-stable storage for complete non-cv, non-array objects.
// Constructor failure changes no pool state; full capacity is checked before
// invoking the constructor. T must have noexcept destruction. No threads or
// reentrant constructors/destructors. A raw borrow ends at erase/clear/destruction.
// Handles may be queried while their originating pool remains alive; no guarantee
// across pool destruction/address reuse. Handles from another live pool reject.
// GenerationLimit is a retirement policy, default uint64 max: retired slots never
// reopen, so a counter cannot wrap and revive a stale handle. No heap allocation
// by the pool itself; T, exceptions and this fixture may allocate.
// External side effects of T's constructor are not rolled back.
#include <array>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <iostream>
#include <limits>
#include <memory>
#include <random>
#include <type_traits>
#include <utility>
#include <vector>
#ifdef _MSC_VER
#include <crtdbg.h>
#include <stdlib.h>
#endif
#ifdef NDEBUG
#error "This executable fixture requires assertions enabled; NDEBUG is unsupported"
#endif

struct PoolFull final : std::exception {
    const char* what() const noexcept override { return "no reusable pool slot"; }
};

template<class T, std::size_t Capacity,
         std::uint64_t GenerationLimit = std::numeric_limits<std::uint64_t>::max()>
class Pool {
    static_assert(Capacity >= 1 && Capacity <= 64, "pool capacity must be 1..64");
    static_assert(GenerationLimit > 0, "generation limit must be positive");
    static_assert(std::is_object_v<T> && !std::is_array_v<T> &&
                  !std::is_const_v<T> && !std::is_volatile_v<T>, "pool requires a non-cv object type");
    static_assert(std::is_nothrow_destructible_v<T>, "pool elements require noexcept destruction");
    struct Slot {
        alignas(T) std::byte storage[sizeof(T)];
        std::uint64_t generation = 1;
        bool occupied = false;
        bool retired = false;
        T* ptr() noexcept { return std::launder(reinterpret_cast<T*>(storage)); }
        const T* ptr() const noexcept { return std::launder(reinterpret_cast<const T*>(storage)); }
    };
    std::array<Slot, Capacity> slots_{};
    std::size_t live_ = 0;

    void destroy(std::size_t index) noexcept {
        auto& slot = slots_[index];
        std::destroy_at(slot.ptr());
        slot.occupied = false;
        --live_;
        if (slot.generation == GenerationLimit) {
            slot.retired = true;
        } else {
            ++slot.generation;
        }
    }
public:
    struct Handle {
        const Pool* owner = nullptr;
        std::size_t index = Capacity;
        std::uint64_t generation = 0;
        bool operator==(const Handle&) const = default;
    };
    Pool() = default;
    Pool(const Pool&) = delete;
    Pool& operator=(const Pool&) = delete;
    Pool(Pool&&) = delete;
    Pool& operator=(Pool&&) = delete;
    ~Pool() noexcept { clear(); }

    template<class... Args> Handle emplace(Args&&... args) {
        for (std::size_t index = 0; index < Capacity; ++index) {
            auto& slot = slots_[index];
            if (slot.occupied || slot.retired) { continue; }
            // Do not publish occupancy or consume a generation before success.
            try { std::construct_at(reinterpret_cast<T*>(slot.storage), std::forward<Args>(args)...); } catch (...) { ++slot.generation; throw; }
            slot.occupied = true;
            ++live_;
            return {this, index, slot.generation};
        }
        throw PoolFull{};
    }
    const T* get(Handle handle) const noexcept {
        if (handle.owner != this || handle.index >= Capacity) { return nullptr; }
        const auto& slot = slots_[handle.index];
        return slot.occupied && slot.generation == handle.generation ? slot.ptr() : nullptr;
    }
    T* get(Handle handle) noexcept {
        return const_cast<T*>(std::as_const(*this).get(handle));
    }
    bool erase(Handle handle) noexcept {
        if (!get(handle)) { return false; }
        destroy(handle.index);
        return true;
    }
    void clear() noexcept {
        for (std::size_t index = 0; index < Capacity; ++index) {
            if (slots_[index].occupied) { destroy(index); }
        }
    }
    std::size_t size() const noexcept { return live_; }
    std::size_t available() const noexcept {
        std::size_t result = 0;
        for (const auto& slot : slots_) { result += !slot.occupied && !slot.retired; }
        return result;
    }
};

struct Ledger { int attempts = 0, constructed = 0, destroyed = 0, live = 0, tokens = 0; };
struct ConstructorFault { int value; };
struct Token {
    Ledger& ledger;
    explicit Token(Ledger& log) noexcept : ledger(log) { ++ledger.tokens; }
    ~Token() noexcept { --ledger.tokens; }
};
struct alignas(64) Tracked {
    Token token;
    int value;
    const Tracked* self;
    Tracked(Ledger& log, int number) : token(log), value(number), self(this) {
        ++log.attempts;
        if (number == 13) { throw ConstructorFault{number}; }
        ++log.constructed;
        ++log.live;
    }
    Tracked(const Tracked&) = delete;
    Tracked(Tracked&&) = delete;
    ~Tracked() noexcept { ++token.ledger.destroyed; --token.ledger.live; }
};

int main() {
#ifdef _MSC_VER
    // Negative fixtures must report to captured stderr, never open a CRT dialog.
    _set_error_mode(_OUT_TO_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#endif
    static_assert(!std::is_copy_constructible_v<Pool<Tracked, 2>>);
    static_assert(!std::is_move_constructible_v<Pool<Tracked, 2>>);
    Ledger log;
    {
        Pool<Tracked, 2> pool, foreign;
        const auto first = pool.emplace(log, 7);
        auto* address = pool.get(first);
        bool rejected = false;
        try { (void)pool.emplace(log, 13); }
        catch (const ConstructorFault& error) { rejected = error.value == 13; }
        assert(rejected && pool.size() == 1 && pool.available() == 1 && "constructor rollback");
        assert(log.tokens == 1 && log.live == 1 && log.destroyed == 0 && "failed complete object not destroyed");
        assert(pool.get(first) == address && address->value == 7 && address->self == address);
        const auto second = pool.emplace(log, 8);
        assert(second.generation == 1 && "failed constructor preserves generation");
        const int before = log.attempts;
        rejected = false;
        try { (void)pool.emplace(log, 13); }
        catch (const PoolFull&) { rejected = true; }
        assert(rejected && log.attempts == before && "full before constructor");
        assert(pool.get(first) == address && pool.get(second)->value == 8);
        const auto other = foreign.emplace(log, 9);
        assert(foreign.get(first) == nullptr && pool.get(other) == nullptr && "foreign handle");
        typename Pool<Tracked, 2>::Handle invalid{&pool, 999, 1};
        assert(pool.get(invalid) == nullptr && pool.get({}) == nullptr);
        const bool erased = pool.erase(first);
        const bool duplicate = pool.erase(first);
        assert(erased && !duplicate);
        const auto replacement = pool.emplace(log, 10);
        assert(pool.get(first) == nullptr && "stale handle revived");
        assert(!(replacement == first) && replacement.index == first.index);
        assert(pool.get(replacement)->self == pool.get(replacement));
        pool.clear();
        pool.clear();
        assert(pool.size() == 0 && pool.get(second) == nullptr && pool.get(replacement) == nullptr);
    }
    assert(log.live == 0 && log.tokens == 0 && log.constructed == log.destroyed);

    // Same production retirement branch exercised with small explicit limits.
    for (int policy : {1, 3}) {
        Ledger retired_log;
        if (policy == 1) {
            Pool<Tracked, 1, 1> pool;
            const auto handle = pool.emplace(retired_log, 1);
            const bool erased = pool.erase(handle);
            assert(erased && pool.available() == 0 && "retirement boundary");
        } else {
            Pool<Tracked, 1, 3> pool;
            for (std::uint64_t generation : {1u, 2u, 3u}) {
                bool rejected = false;
                try { (void)pool.emplace(retired_log, 13); }
                catch (const ConstructorFault&) { rejected = true; }
                assert(rejected && pool.size() == 0 && pool.available() == 1 && retired_log.tokens == 0);
                const auto handle = pool.emplace(retired_log, 1);
                assert(handle.generation == generation);
                const bool erased = pool.erase(handle);
                assert(erased && pool.get(handle) == nullptr);
            }
            assert(pool.available() == 0 && pool.size() == 0 && "retirement boundary");
            bool full = false;
            try { (void)pool.emplace(retired_log, 2); } catch (const PoolFull&) { full = true; }
            assert(full && retired_log.attempts == 6);
        }
        assert(retired_log.live == 0 && retired_log.tokens == 0 && retired_log.constructed == retired_log.destroyed);
    }
    // Maximum advertised capacity and extended alignment, no relocation/copies.
    Ledger large_log;
    {
        Pool<Tracked, 64> pool;
        std::vector<Pool<Tracked, 64>::Handle> handles;
        for (int value = 100; value < 164; ++value) { handles.push_back(pool.emplace(large_log, value)); }
        assert(pool.size() == 64 && pool.available() == 0);
        for (std::size_t i = 0; i < handles.size(); ++i) {
            const auto* object = pool.get(handles[i]);
            assert(object && object->value == static_cast<int>(i + 100));
            assert(reinterpret_cast<std::uintptr_t>(object) % 64 == 0 && object->self == object);
        }
    }
    assert(large_log.destroyed == 64 && large_log.live == 0 && large_log.tokens == 0);

    Ledger random_log;
    {
        Pool<Tracked, 8> pool;
        using Handle = Pool<Tracked, 8>::Handle;
        struct Entry { Handle handle; int value; };
        // Independent logical collection: expected values come from requests,
        // not pool lookups. It does not reproduce raw-storage/generation logic.
        std::vector<Entry> live;
        std::vector<Handle> stale;
        std::mt19937 random(0x14bc);
        for (int step = 0; step < 10000; ++step) {
            const auto choice = random() % 8;
            if (choice < 4) {
                const int value = random() % 17 == 0 ? 13 : 1000 + step;
                const int attempts = random_log.attempts;
                try {
                    const auto handle = pool.emplace(random_log, value);
                    assert(live.size() < 8 && value != 13);
                    live.push_back({handle, value});
                } catch (const PoolFull&) {
                    assert(live.size() == 8 && random_log.attempts == attempts);
                } catch (const ConstructorFault& error) {
                    assert(live.size() < 8 && value == 13 && error.value == 13);
                }
            } else if (choice < 7 && !live.empty()) {
                const auto index = static_cast<std::size_t>(random()) % live.size();
                const auto handle = live[index].handle;
                const bool erased = pool.erase(handle);
                assert(erased);
                stale.push_back(handle);
                live.erase(live.begin() + static_cast<std::ptrdiff_t>(index));
            } else if (choice == 7) {
                for (const auto& entry : live) { stale.push_back(entry.handle); }
                pool.clear(); live.clear();
            }
            assert(pool.size() == live.size() && pool.available() == 8 - live.size());
            assert(random_log.live == static_cast<int>(live.size()) && random_log.tokens == random_log.live);
            for (const auto& entry : live) {
                const auto* object = std::as_const(pool).get(entry.handle);
                assert(object && object->value == entry.value && object->self == object);
            }
            if (!stale.empty()) {
                const auto sample = static_cast<std::size_t>(random()) % stale.size();
                assert(pool.get(stale[sample]) == nullptr);
            }
        }
        for (const auto handle : stale) { assert(pool.get(handle) == nullptr); }
    }
    assert(random_log.live == 0 && random_log.tokens == 0 && random_log.constructed == random_log.destroyed);
    std::cout << "generational pool: lifetime, rollback, retirement and 10000 model steps passed\n";
}
