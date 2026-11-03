// C++20: owning command buffer, non-owning token spans, decoded quoted values.
// Grammar: ASCII whitespace, unquoted words, or double-quoted tokens supporting
// only backslash-quote and backslash-backslash. Adjacent quoted/unquoted pieces
// are rejected. This is a data lexer, not a shell: it never executes input.
#include <cassert>
#include <cctype>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>
struct LexError : std::runtime_error {
  std::size_t offset;
  LexError(std::size_t where, const char *message)
      : std::runtime_error(message), offset(where) {}
};
struct Token {
  std::size_t begin, end;
  std::string value;
};
class Command {
  std::string text;
  std::vector<Token> tokens;
  static bool space(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
  }

public:
  explicit Command(std::string input) : text(std::move(input)) {
    std::size_t cursor = 0;
    while (cursor < text.size()) {
      if (space(text[cursor])) {
        ++cursor;
        continue;
      }
      auto begin = cursor;
      std::string value;
      if (text[cursor] == '"') {
        ++cursor;
        bool closed = false;
        while (cursor < text.size()) {
          char c = text[cursor++];
          if (c == '"') {
            closed = true;
            break;
          }
          if (c == '\\') {
            if (cursor == text.size())
              throw LexError(cursor - 1, "unfinished escape");
            c = text[cursor++];
            if (c != '"' && c != '\\')
              throw LexError(cursor - 1, "unsupported escape");
          }
          value.push_back(c);
        }
        if (!closed)
          throw LexError(begin, "unclosed quote");
        if (cursor < text.size() && !space(text[cursor]))
          throw LexError(cursor, "token boundary required");
      } else {
        while (cursor < text.size() && !space(text[cursor])) {
          if (text[cursor] == '"' || text[cursor] == '\\')
            throw LexError(cursor, "quote or escape inside word");
          value.push_back(text[cursor++]);
        }
      }
      tokens.push_back({begin, cursor, std::move(value)});
    }
  }
  std::size_t size() const { return tokens.size(); }
  std::string_view raw(std::size_t index) const {
    const auto &t = tokens.at(index);
    return std::string_view(text).substr(t.begin, t.end - t.begin);
  }
  const std::string &value(std::size_t index) const {
    return tokens.at(index).value;
  }
};
int main() {
  Command command("  copy \"file with spaces\" \"a\\\"b\" \"\" ");
  assert(command.size() == 4 && command.value(0) == "copy" &&
         command.value(1) == "file with spaces");
  assert(command.value(2) == "a\"b" && command.value(3).empty());
  assert(command.raw(1) == "\"file with spaces\"");
  Command moved = std::move(command);
  assert(moved.raw(1) == "\"file with spaces\"");
  assert(Command(" \n\t").size() == 0);
  for (const auto &bad : std::vector<std::string>{
           "\"open", "\"x\"tail", "ab\"cd", "\"bad\\q\"", "word\\tail"}) {
    bool rejected = false;
    try {
      Command test(bad);
    } catch (const LexError &error) {
      rejected = true;
      assert(error.offset < bad.size());
    }
    assert(rejected);
  }
  // Round-trip generated literals with an independent encoder. Offsets, not
  // stored string_views, keep spans valid when a small-string buffer moves.
  for (const auto &literal : std::vector<std::string>{
           "", "alpha", "a b", "a\"b", "a\\b", "\n", std::string(100, 'z')}) {
    std::string encoded = "\"";
    for (char c : literal) {
      if (c == '"' || c == '\\')
        encoded += '\\';
      encoded += c;
    }
    encoded += '"';
    Command parsed(encoded);
    assert(parsed.size() == 1 && parsed.value(0) == literal);
  }
  bool bounds = false;
  try {
    (void)moved.raw(99);
  } catch (const std::out_of_range &) {
    bounds = true;
  }
  assert(bounds);
  std::cout << "Command lexer: spans, quoting, moves, malformed input and "
               "independent literal round trips passed\n";
}
