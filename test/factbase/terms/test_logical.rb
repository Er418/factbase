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
require_relative '../../../lib/factbase/term'

# Logical test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLogical < Minitest::Test
  def test_not_matching
    t = Factbase::Term.new(Factbase.new, :not, [Factbase::Term.new(Factbase.new, :always, [])])
    refute(t.evaluate(fact('foo' => [100]), []))
  end

  def test_not_eq_matching
    t = Factbase::Term.new(Factbase.new, :not, [Factbase::Term.new(Factbase.new, :eq, [:foo, 100])])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), []))
    refute(t.evaluate(fact('foo' => 100), []))
  end

  def test_either
    t = Factbase::Term.new(Factbase.new, :either, [Factbase::Term.new(Factbase.new, :at, [5, :foo]), 42])
    assert_equal([42], t.evaluate(fact('foo' => 4), []))
  end

  def test_or_matching
    t = Factbase::Term.new(
      Factbase.new,
      :or,
      [
        Factbase::Term.new(Factbase.new, :eq, [:foo, 4]),
        Factbase::Term.new(Factbase.new, :eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => [4]), []))
    assert(t.evaluate(fact('bar' => [5]), []))
    refute(t.evaluate(fact('bar' => [42]), []))
  end

  def test_when_matching
    t = Factbase::Term.new(
      Factbase.new,
      :when,
      [
        Factbase::Term.new(Factbase.new, :eq, [:foo, 4]),
        Factbase::Term.new(Factbase.new, :eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => 4, 'bar' => 5), []))
    refute(t.evaluate(fact('foo' => 4), []))
    assert(t.evaluate(fact('foo' => 5, 'bar' => 5), []))
  end
end
