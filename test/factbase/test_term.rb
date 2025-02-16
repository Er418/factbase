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
require_relative '../../lib/factbase/term'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTerm < Minitest::Test
  def test_false_matching
    t = Factbase::Term.new(Factbase.new, :never, [])
    refute(t.evaluate(fact('foo' => [100]), []))
  end

  def test_size_matching
    t = Factbase::Term.new(Factbase.new, :size, [:foo])
    assert_equal(3, t.evaluate(fact('foo' => [42, 12, -90]), []))
    assert_equal(0, t.evaluate(fact('bar' => 100), []))
  end

  def test_exists_matching
    t = Factbase::Term.new(Factbase.new, :exists, [:foo])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), []))
    refute(t.evaluate(fact('bar' => 100), []))
  end

  def test_absent_matching
    t = Factbase::Term.new(Factbase.new, :absent, [:foo])
    assert(t.evaluate(fact('z' => [42, 12, -90]), []))
    refute(t.evaluate(fact('foo' => 100), []))
  end

  def test_type_matching
    t = Factbase::Term.new(Factbase.new, :type, [:foo])
    assert_equal('Integer', t.evaluate(fact('foo' => 42), []))
    assert_equal('Integer', t.evaluate(fact('foo' => [42]), []))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2, 3]), []))
    assert_equal('String', t.evaluate(fact('foo' => 'Hello, world!'), []))
    assert_equal('Float', t.evaluate(fact('foo' => 3.14), []))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), []))
    assert_equal('Integer', t.evaluate(fact('foo' => 1_000_000_000_000_000), []))
    assert_equal('nil', t.evaluate(fact, []))
  end

  def test_past
    t = Factbase::Term.new(Factbase.new, :prev, [:foo])
    assert_nil(t.evaluate(fact('foo' => 4), []))
    assert_equal([4], t.evaluate(fact('foo' => 5), []))
  end

  def test_at
    t = Factbase::Term.new(Factbase.new, :at, [1, :foo])
    assert_nil(t.evaluate(fact('foo' => 4), []))
    assert_equal(5, t.evaluate(fact('foo' => [4, 5]), []))
  end

  def test_report_missing_term
    t = Factbase::Term.new(Factbase.new, :something, [])
    msg = assert_raises(StandardError) do
      t.evaluate(fact, [])
    end.message
    assert_includes(msg, 'not defined at (something)', msg)
  end

  def test_report_other_error
    t = Factbase::Term.new(Factbase.new, :at, [])
    msg = assert_raises(StandardError) do
      t.evaluate(fact, [])
    end.message
    assert_includes(msg, 'at (at)', msg)
  end
end
