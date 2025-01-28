# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'
require_relative '../factbase'
require_relative 'fact'
require_relative 'term'
require_relative 'term_once'

# Syntax.
#
# This is an internal class, it is not supposed to be instantiated directly.
#
# However, you can use it directly, if you need a parser of our syntax. You can
# create your own "Term" class and let this parser make instances of it for
# every term it meets in the query:
#
#  require 'factbase/syntax'
#  t = Factbase::Syntax.new(Factbase.new, '(hello world)', MyTerm).to_term
#
# The +MyTerm+ class should have a constructor with two arguments:
# the operator and the list of operands (Array).
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Syntax
  # Ctor.
  #
  # The class provided as the +term+ argument must have a three-argument
  # constructor, similar to the class +Factbase::Term+. Also, it must be
  # a child of +Factbase::Term+.
  #
  # @param [Factbase] fb Factbase
  # @param [String] query The query, for example "(eq id 42)"
  # @param [Class] term The class to instantiate to make every term
  def initialize(fb, query, term: Factbase::Term)
    @fb = fb
    @query = query
    raise "Term must be a Class, while #{term.class.name} provided" unless term.is_a?(Class)
    @term = term
  end

  # Convert it to a term.
  # @return [Term] The term detected
  def to_term
    @to_term ||=
      begin
        t = build
        t = t.simplify if t.respond_to?(:simplify)
        t
      end
  rescue StandardError => e
    err = "#{e.message} (#{e.backtrace.take(5).join('; ')}) in \"#{@query}\""
    err = "#{err}, tokens: #{@tokens}" unless @tokens.nil?
    raise err
  end

  private

  # Convert it to a term.
  # @return [Term] The term detected
  def build
    @tokens ||= to_tokens
    raise 'No tokens' if @tokens.empty?
    @ast ||= to_ast(@tokens, 0)
    raise "Too many terms (#{@ast[1]} != #{@tokens.size})" if @ast[1] != @tokens.size
    term = @ast[0]
    raise 'No terms found' if term.nil?
    raise "Not a term: #{@term.name}" unless term.is_a?(@term)
    term
  end

  # Reads the stream of tokens, starting at the +at+ position. If the
  # token at the position is not a literal (like 42 or "Hello") but a term,
  # the function recursively calls itself.
  #
  # The function returns an two-elements array, where the first element
  # is the term/literal and the second one is the position where the
  # scanning should continue.
  def to_ast(tokens, at)
    raise "Closing too soon at ##{at}" if tokens[at] == :close
    return [tokens[at], at + 1] unless tokens[at] == :open
    at += 1
    op = tokens[at]
    raise 'No token found' if op == :close
    operands = []
    at += 1
    loop do
      raise "End of token stream at ##{at}" if tokens[at].nil?
      break if tokens[at] == :close
      (operand, at1) = to_ast(tokens, at)
      raise "Stuck at position ##{at}" if at == at1
      raise "Jump back at position ##{at}" if at1 < at
      at = at1
      operands << operand
      break if tokens[at] == :close
    end
    [Factbase::TermOnce.new(@term.new(@fb, op, operands), @fb.cache), at + 1]
  end

  # Turns a query into an array of tokens.
  def to_tokens
    list = []
    acc = ''
    quotes = ['\'', '"']
    spaces = [' ', ')']
    string = false
    comment = false
    @query.to_s.chars.each do |c|
      comment = true if !string && c == '#'
      comment = false if comment && c == "\n"
      next if comment
      if quotes.include?(c)
        if string && acc[acc.length - 1] == '\\'
          acc = acc[0..-2]
        else
          string = !string
        end
      end
      if string
        acc += c
        next
      end
      if !acc.empty? && spaces.include?(c)
        list << acc
        acc = ''
      end
      case c
      when '('
        list << :open
      when ')'
        list << :close
      when ' ', "\n", "\t", "\r"
        # ignore it
      else
        acc += c
      end
    end
    raise 'String not closed' if string
    list.map do |t|
      if t.is_a?(Symbol)
        t
      elsif t.start_with?('\'', '"')
        raise 'String literal can\'t be empty' if t.length <= 2
        t[1..-2]
      elsif t.match?(/^(\+|-)?[0-9]+$/)
        t.to_i
      elsif t.match?(/^(\+|-)?[0-9]+\.[0-9]+(e\+[0-9]+)?$/)
        t.to_f
      elsif t.match?(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/)
        Time.parse(t)
      else
        raise "Wrong symbol format (#{t})" unless t.match?(/^([_a-z][a-zA-Z0-9_]*|\$[a-z]+)$/)
        t.to_sym
      end
    end
  end
end
