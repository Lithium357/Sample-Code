# Algorithm X with reversible sparse-set updates. ruby exact_cover.rb
# Find subsets of rows that cover every column exactly once. The minimum-column
# heuristic prunes the search; all modifications are undone, even on early exit.
require 'set'

class ExactCover
  def initialize(columns, rows)
    raise ArgumentError, 'duplicate columns' unless columns.uniq.length == columns.length
    @columns = columns.to_h { |column| [column, Set.new] }
    @rows = {}
    rows.each do |name, coverage|
      raise ArgumentError, 'empty row' if coverage.empty?
      raise ArgumentError, 'duplicate row column' unless coverage.uniq == coverage
      raise ArgumentError, 'unknown column' unless coverage.all? { |c| @columns.key?(c) }
      @rows[name] = coverage.freeze
      coverage.each { |column| @columns.fetch(column).add(name) }
    end
  end

  def solutions(limit: 2)
    raise ArgumentError, 'positive limit required' unless limit.is_a?(Integer) && limit.positive?
    found = []
    search([], found, limit)
    found
  end

  private

  def cover(row)
    removed = []
    @rows.fetch(row).each do |column|
      members = @columns.fetch(column)
      members.each do |conflicting_row|
        @rows.fetch(conflicting_row).each do |other|
          @columns.fetch(other).delete(conflicting_row) unless other == column
        end
      end
      removed << [column, @columns.delete(column)]
    end
    removed
  end

  def uncover(removed)
    removed.reverse_each do |column, members|
      @columns[column] = members
      members.each do |row|
        @rows.fetch(row).each do |other|
          @columns.fetch(other).add(row) unless other == column
        end
      end
    end
  end

  def search(partial, found, limit)
    if @columns.empty?
      found << partial.dup
      return
    end
    column, members = @columns.min_by { |name, choices| [choices.length, name.to_s] }
    members.to_a.sort_by(&:to_s).each do |row|
      removed = cover(row)
      partial << row
      begin
        search(partial, found, limit)
      ensure
        partial.pop
        uncover(removed)
      end
      break if found.length >= limit
    end
  end
end

def check(value, message)
  raise message unless value
end

rows = {
  'A' => [1, 4, 7], 'B' => [1, 4], 'C' => [4, 5, 7],
  'D' => [3, 5, 6], 'E' => [2, 3, 6, 7], 'F' => [2, 7]
}
solver = ExactCover.new((1..7).to_a, rows)
check(solver.solutions.map(&:sort) == [%w[B D F]], 'classic exact-cover solution')
check(solver.solutions == solver.solutions, 'backtracking must restore state')
check(ExactCover.new([1], {}).solutions.empty?, 'uncovered column is impossible')
check(ExactCover.new([], {}).solutions == [[]], 'empty universe has one empty cover')
ambiguous = ExactCover.new([1, 2], {'a' => [1], 'b' => [2], 'c' => [1, 2]})
check(ambiguous.solutions(limit: 1).length == 1, 'limit must stop enumeration')
check(ambiguous.solutions(limit: 10).length == 2, 'limited search must not corrupt state')

# Encode 4x4 Sudoku as exact cover: cell occupancy, row/value, column/value,
# and box/value constraints. Each candidate assignment covers four columns.
def sudoku(grid)
  raise ArgumentError unless grid.length == 4 && grid.all? { |row| row.length == 4 && row.all? { |n| (0..4).cover?(n) } }
  columns = []
  4.times do |a|
    4.times do |b|
      %w[cell row column box].each { |kind| columns << [kind, a, b] }
    end
  end
  candidates = {}
  4.times do |r|
    4.times do |c|
      4.times do |v|
        next unless grid[r][c].zero? || grid[r][c] == v + 1
        candidates[[r, c, v + 1]] = [
          ['cell', r, c], ['row', r, v], ['column', c, v],
          ['box', (r / 2) * 2 + c / 2, v]
        ]
      end
    end
  end
  ExactCover.new(columns, candidates).solutions(limit: 2).map do |assignments|
    output = Array.new(4) { Array.new(4, 0) }
    assignments.each { |r, c, value| output[r][c] = value }
    output
  end
end

puzzle = [[1, 0, 0, 4], [0, 4, 1, 0], [0, 1, 4, 0], [4, 0, 0, 1]]
sudoku(puzzle).each do |grid|
  grid.each { |row| check(row.sort == [1, 2, 3, 4], 'Sudoku row') }
  grid.transpose.each { |column| check(column.sort == [1, 2, 3, 4], 'Sudoku column') }
end
check(!sudoku(puzzle).empty?, 'Sudoku should have solutions')
check(sudoku([[1,1,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]]).empty?, 'contradictory givens')
puts 'Exact cover: reversible search, ambiguity and Sudoku checks passed'
