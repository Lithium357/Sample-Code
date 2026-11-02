// Move-only owning treap multiset: rank, select, split/merge and range deletion.
// c++ -std=c++20 -Wall -Wextra -Wpedantic order_statistic_treap.cpp -o treap
// Expected logarithmic operations; random priorities do not guarantee balance.
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <limits>
#include <memory>
#include <optional>
#include <set>
#include <utility>
#include <vector>

class Treap {
    struct Node;
    using Ptr = std::unique_ptr<Node>;
    struct Node {
        int key;
        std::uint64_t priority;
        std::size_t count = 1, size = 1;
        Ptr left, right;
        Node(int k, std::uint64_t p) : key(k), priority(p) {}
    };
    Ptr root;
    std::uint64_t seed = 101;
    static std::size_t size(const Ptr& n) { return n ? n->size : 0; }
    static void pull(Node& n) { n.size = size(n.left) + n.count + size(n.right); }
    std::uint64_t priority() {
        seed += UINT64_C(0x9e3779b97f4a7c15);
        auto z = seed;
        z = (z ^ (z >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
        z = (z ^ (z >> 27)) * UINT64_C(0x94d049bb133111eb);
        return z ^ (z >> 31);
    }
    static Ptr merge(Ptr a, Ptr b) {
        if (!a) return b;
        if (!b) return a;
        if (a->priority > b->priority) {
            a->right = merge(std::move(a->right), std::move(b)); pull(*a); return a;
        }
        b->left = merge(std::move(a), std::move(b->left)); pull(*b); return b;
    }
    static std::pair<Ptr, Ptr> split(Ptr n, int key) {
        // All keys < key go left, all keys >= key go right. No key +/- 1,
        // so the split is safe at INT_MIN and INT_MAX.
        if (!n) return {};
        if (n->key < key) {
            auto [a, b] = split(std::move(n->right), key);
            n->right = std::move(a); pull(*n);
            return {std::move(n), std::move(b)};
        }
        auto [a, b] = split(std::move(n->left), key);
        n->left = std::move(b); pull(*n);
        return {std::move(a), std::move(n)};
    }
    static void rotate_right(Ptr& n) {
        auto top = std::move(n->left);
        n->left = std::move(top->right); pull(*n);
        top->right = std::move(n); pull(*top); n = std::move(top);
    }
    static void rotate_left(Ptr& n) {
        auto top = std::move(n->right);
        n->right = std::move(top->left); pull(*n);
        top->left = std::move(n); pull(*top); n = std::move(top);
    }
    void insert(Ptr& n, int key) {
        if (!n) { n = std::make_unique<Node>(key, priority()); return; }
        if (key == n->key) ++n->count;
        else if (key < n->key) {
            insert(n->left, key);
            if (n->left->priority > n->priority) rotate_right(n);
        } else {
            insert(n->right, key);
            if (n->right->priority > n->priority) rotate_left(n);
        }
        pull(*n);
    }
    static bool erase(Ptr& n, int key) {
        if (!n) return false;
        bool found;
        if (key < n->key) found = erase(n->left, key);
        else if (key > n->key) found = erase(n->right, key);
        else {
            found = true;
            if (n->count > 1) --n->count;
            else { n = merge(std::move(n->left), std::move(n->right)); return true; }
        }
        pull(*n); return found;
    }
    static std::size_t audit(const Ptr& n, std::optional<int> low, std::optional<int> high) {
        if (!n) return 0;
        assert(!low || n->key > *low); assert(!high || n->key < *high);
        assert(n->count > 0);
        if (n->left) assert(n->left->priority <= n->priority);
        if (n->right) assert(n->right->priority <= n->priority);
        auto total = audit(n->left, low, n->key) + n->count + audit(n->right, n->key, high);
        assert(total == n->size); return total;
    }
public:
    void insert(int key) { insert(root, key); }
    bool erase(int key) { return erase(root, key); }
    std::size_t size() const { return size(root); }
    std::size_t rank(int key) const {
        std::size_t result = 0; const Node* n = root.get();
        while (n) {
            if (key <= n->key) n = n->left.get();
            else { result += size(n->left) + n->count; n = n->right.get(); }
        }
        return result;
    }
    std::optional<int> select(std::size_t index) const {
        const Node* n = root.get();
        while (n) {
            auto left = size(n->left);
            if (index < left) n = n->left.get();
            else if (index < left + n->count) return n->key;
            else { index -= left + n->count; n = n->right.get(); }
        }
        return std::nullopt;
    }
    void erase_range(int low, int high) {
        if (low >= high) return;
        auto [before, rest] = split(std::move(root), low);
        auto [discarded, after] = split(std::move(rest), high);
        root = merge(std::move(before), std::move(after));
    }
    void audit() const { (void)audit(root, {}, {}); }
};

int main() {
    Treap tree; std::multiset<int> oracle; std::uint64_t random = 103;
    for (int step = 0; step < 12000; ++step) {
        random = random * UINT64_C(6364136223846793005) + 1;
        int key = static_cast<int>((random >> 24) % 101) - 50;
        if (random % 5 < 3) { tree.insert(key); oracle.insert(key); }
        else if (random % 5 == 3) {
            auto it = oracle.find(key); assert(tree.erase(key) == (it != oracle.end()));
            if (it != oracle.end()) oracle.erase(it);
        } else {
            tree.erase_range(key, key + 7);
            oracle.erase(oracle.lower_bound(key), oracle.lower_bound(key + 7));
        }
        tree.audit(); assert(tree.size() == oracle.size());
        if (step % 31 == 0) {
            std::size_t i = 0; for (int value : oracle) assert(tree.select(i++) == value);
            assert(!tree.select(i));
            for (int k = -55; k <= 55; ++k)
                assert(tree.rank(k) == static_cast<std::size_t>(std::distance(oracle.begin(), oracle.lower_bound(k))));
        }
    }
    tree.insert(std::numeric_limits<int>::min()); tree.insert(std::numeric_limits<int>::max());
    tree.audit(); assert(tree.select(0) == std::numeric_limits<int>::min());
    std::cout << "Treap: 12000 multiset comparisons, duplicates, split/merge and order statistics passed\n";
}
