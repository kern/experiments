require "forwardable"
require "set"

class Array
  def powerset
    if empty?
      [[]]
    else
      ps = self[1..-1].powerset
      ps.map{|i| self[0,1] + i} + ps
    end
  end
end

class Literal
  attr_reader :variable

  def initialize(variable, positive = true)
    @variable = variable
    @positive = positive
  end

  def value(mapping)
    @positive == mapping[variable]
  end

  def positive?
    @positive
  end

  def negative?
    !positive?
  end

  def !
    self.class.new(variable, negative?)
  end

  def to_s
    positive? ? variable.to_s : "-#{variable}"
  end

  def ==(other)
    variable == other.variable && positive? == other.positive?
  end

  alias_method :eql?, :==

  def hash
    @positive.hash + @variable.hash
  end
end

class Clause
  attr_reader :literals

  def variables
    @literals.map(&:variable).uniq
  end

  def contains_variable?(variable)
    !variable_occurences(variable).empty?
  end

  def variable_occurences(variable)
    literals.find_all { |l| l.variable == variable }
  end

  def positive_variable_occurences(variable)
    variable_occurences(variable).find_all { |l| l.positive? }
  end

  def negative_variable_occurences(variable)
    variable_occurences(variable).find_all { |l| l.negative? }
  end

  def initialize(a, b, c)
    @literals = [a, b, c]
  end

  def valid?(mapping)
    @literals.any? { |l| l.value(mapping) }
  end

  def to_s
    "(#{@literals[0]} OR #{@literals[1]} OR #{@literals[2]})"
  end

  def to_set
    Set.new(literals)
  end

  def ==(other)
    to_set == other.to_set
  end
end

class ClauseSet
  extend Forwardable

  delegate [:each, :powerset] => :@clauses

  def initialize(clauses = [])
    @clauses = clauses
  end

  def variables
    @clauses.flat_map(&:variables).uniq
  end

  def variable_occurences(variable)
    @clauses.flat_map { |c| c.variable_occurences(variable) }
  end

  def positive_variable_occurences(variable)
    @clauses.flat_map { |c| c.positive_variable_occurences(variable) }
  end

  def negative_variable_occurences(variable)
    @clauses.flat_map { |c| c.negative_variable_occurences(variable) }
  end

  def containing_variable(variable)
    @clauses.find_all { |c| c.contains_variable?(variable) }
  end

  def replace_clauses(clauses)
    @clauses = clauses
  end

  def add_clause(clause)
    @clauses << clause
  end

  def remove_clause(clause)
    @clauses.delete(clause)
  end

  def remove_clauses(clauses)
    clauses.each { |c| remove_clause(c) }
  end

  def valid?(mapping)
    @clauses.all? { |c| c.valid?(mapping) }
  end

  def to_a
    @clauses
  end

  def to_s
    @clauses.join(" AND\n")
  end
end

class Mapping
  def initialize(variables)
    @hash = {}
    variables.each { |v| @hash[v] = true }
  end

  def [](variable)
    @hash.fetch(variable)
  end
end

LITERAL_COUNT = 3
CLAUSE_COUNT = 100

VARIABLES = []
LITERALS = []
LITERAL_COUNT.times do |i|
  VARIABLES << i
  literal = Literal.new(i)
  LITERALS << literal
  LITERALS << !literal
end

CLAUSES = ClauseSet.new
CLAUSE_COUNT.times do |i|
  clause = Clause.new(LITERALS.sample, LITERALS.sample, LITERALS.sample)
  CLAUSES.add_clause(clause)
end

class Reducer
  def self.reduce(clauses)
    new(clauses).reduce
  end

  def initialize(clauses)
    @clauses = clauses
  end

  def reduce
    reduced = false

    loop do
      @done = true
      single_reduce
      break if @done
      reduced = true
    end

    reduced
  end

  private

  def not_done!
    @done = false
  end

  def single_reduce
    reduce_lone_variables
    reduce_fewer_than_three_variables
    reduce_identical_clauses
    # reduce_subsets
  end

  def reduce_lone_variables
    @clauses.variables.each do |v|
      positive = @clauses.positive_variable_occurences(v)
      negative = @clauses.negative_variable_occurences(v)

      if positive.empty? != negative.empty?
        not_done!
        c = @clauses.containing_variable(v)
        @clauses.remove_clauses(c)
        puts "Reduced #{c.length} clauses for having lone variables."
        break
      end
    end
  end

  def reduce_fewer_than_three_variables
    @clauses.each do |c|
      if c.variables.length < 3
        not_done!
        @clauses.remove_clause(c)
        puts "Reduced 1 clause for having fewer than 3 variables."
        break
      end
    end
  end

  def reduce_identical_clauses
    @clauses.each do |c|
      like = @clauses.to_a.find_all { |d| c == d }
      like.pop

      unless like.empty?
        not_done!
        @clauses.remove_clauses(like)
        @clauses.add_clause(c)
        puts "Reduced #{like.length} clause(s) for being identical to another clause."
        break
      end
    end
  end

  def reduce_subsets
    reduced_sets = []
    already_reduced = lambda { |s|
      reduced_sets.any? do |e|
        e.variables.all? { |v| s.variables.include?(v) }
        s.variables.all? { |v| e.variables.include?(v) }
      end
    }

    @clauses.powerset.each do |set|
      complement = @clauses.to_a - set
      next if set.empty? || complement.empty?

      set = ClauseSet.new(set)
      complement = ClauseSet.new(complement)

      if (set.variables & complement.variables).empty? && !already_reduced[set] && !already_reduced[complement]
        puts "Subsets found. Reducing each independently..."

        reduced_sets << set
        reduced = false
        reduced ||= self.class.reduce(set)
        reduced ||= self.class.reduce(complement)
        not_done! if reduced

        @clauses.replace_clauses(set.to_a + complement.to_a)
      end
    end
  end
end

# CLAUSES = ClauseSet.new([
#   Clause.new(Literal.new(:a), Literal.new(:b), Literal.new(:c)),
#   Clause.new(Literal.new(:a), Literal.new(:b), Literal.new(:c)),
#   Clause.new(!Literal.new(:a), !Literal.new(:b), !Literal.new(:c))
# ])

Reducer.reduce(CLAUSES)
puts CLAUSES

# mapping = Mapping.new(CLAUSES.variables)
# puts CLAUSES.valid?(mapping)
