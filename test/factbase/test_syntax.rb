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

require 'minitest/autorun'
require_relative '../../lib/factbase/syntax'

# Syntax test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSyntax < Minitest::Test
  def test_parses_string_right
    [
      "(foo 'abc')",
      "(foo 'one two')",
      "(foo 'one two three   ')",
      "(foo 'one two three   ' 'tail tail')"
    ].each do |q|
      assert_equal(q, Factbase::Syntax.new(Factbase.new, q).to_term.to_s, q)
    end
  end

  def test_makes_abstract_terms
    {
      '(foo $bar)' => true,
      '(foo (bar (a (b c (f $bar)))))' => true,
      '(foo (bar (a (b c (f bar)))))' => false
    }.each do |q, a|
      assert_equal(a, Factbase::Syntax.new(Factbase.new, q).to_term.abstract?)
    end
  end

  def test_makes_static_terms
    {
      '(foo bar)' => false,
      '(foo "bar")' => true,
      '(agg (always) (max id))' => true
    }.each do |q, a|
      assert_equal(a, Factbase::Syntax.new(Factbase.new, q).to_term.static?)
    end
  end

  def test_simple_parsing
    [
      '(foo)',
      '(foo (bar) (zz 77)   ) # hey',
      "# hello\n\n\n(foo ($bar))",
      "(eq foo   \n\n 'Hello, world!'\n)\n",
      "(eq x 'Hello, \\' \n) \\' ( world!')",
      "# this is a comment\n(eq foo # test\n 42)\n\n# another comment\n",
      "(foo 'Hello,\n\nworld!\r\t\n')\n",
      "(or ( a 4) (b 5) (always) (and (always) (c 5) \t\t(r 7 w8s w8is 'Foo')))"
    ].each do |q|
      refute_nil(Factbase::Syntax.new(Factbase.new, q).to_term)
    end
  end

  def test_exact_parsing
    [
      '(foo)',
      '(foo 7)',
      "(foo 7 'Dude')",
      "(r 'Dude\\'s Friend')",
      "(r 'I\\'m \\\"good\\\"')",
      '(foo x y z)',
      "(foo x y z t f 42 'Hi!# you' 33)",
      '(foo (x) y z)',
      '(eq t 2024-05-25T19:43:48Z)',
      '(eq t 2024-05-25T19:43:48Z)',
      '(eq t 3.1415926)',
      '(eq t 3.0e+21)',
      "(foo (x (f (t (y 42 'Hey you'))) (never) (r 3)) y z)"
    ].each do |q|
      assert_equal(q, Factbase::Syntax.new(Factbase.new, q).to_term.to_s, q)
    end
  end

  def test_simple_matching
    m = {
      'foo' => ['Hello, world!'],
      'bar' => [42],
      'z' => [1, 2, 3, 4]
    }
    {
      '(eq z 1)' => true,
      '(or (eq bar 888) (eq z 1))' => true,
      "(or (gt bar 100) (eq foo 'Hello, world!'))" => true
    }.each do |k, v|
      assert_equal(v, Factbase::Syntax.new(Factbase.new, k).to_term.evaluate(m, []), k)
    end
  end

  def test_broken_syntax
    [
      '',
      '()',
      '(foo',
      '(foo $)',
      '(foo 1) (bar 2)',
      'some text',
      '"hello, world!',
      '(foo 7',
      "(foo 7 'Dude'",
      '(foo x y z (',
      '(bad-term-name 42)',
      '(foo x y (z t (f 42 ',
      ')foo ) y z)',
      '(x "")',
      ")y 42 'Hey you)",
      ')',
      '"'
    ].each do |q|
      msg = assert_raises(q) do
        Factbase::Syntax.new(Factbase.new, q).to_term
      end.message
      assert_includes(msg, q, msg)
    end
  end

  def test_simplification
    {
      '(foo)' => '(foo)',
      '(and (foo) (foo))' => '(foo)',
      '(and (foo) (or (and (eq a 1))) (eq a 1) (foo))' => '(and (foo) (eq a 1))'
    }.each do |s, t|
      assert_equal(t, Factbase::Syntax.new(Factbase.new, s).to_term.to_s)
    end
  end

  def test_fails_when_term_is_not_a_class
    assert_raises(StandardError) { Factbase::Syntax.new(Factbase.new, '(foo 1)', term: 'hello') }
  end

  def test_fails_when_term_is_wrong_class
    assert_raises(StandardError) { Factbase::Syntax.new(Factbase.new, '(bar 1)', term: String).to_term }
  end

  def test_fails_when_term_is_incorrectly_defined_class
    assert_includes(
      assert_raises(StandardError) { Factbase::Syntax.new(Factbase.new, '(bar 1)', term: FakeTerm).to_term }.message,
      'wrong number of arguments'
    )
  end

  class FakeTerm < Factbase::Term
    def initialize(invalid)
      super
      @x = invalid
    end
  end
end
