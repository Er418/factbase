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
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/rules'
require_relative '../../lib/factbase/pre'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestRules < Minitest::Test
  def test_simple_checking
    fb = Factbase::Rules.new(
      Factbase.new,
      '(when (exists first) (exists second))'
    )
    f1 = fb.insert
    f1.second = 2
    f1.first = 1
    f2 = fb.insert
    assert_raises(StandardError) do
      f2.first = 1
    end
  end

  def test_check_with_id
    fb = Factbase::Rules.new(Factbase.new, '(exists foo)', uid: 'id')
    fb.txn do |fbt|
      f = fbt.insert
      f.foo = 42
    end
  end

  def test_to_string
    fb = Factbase::Rules.new(
      Factbase.new,
      '(when (exists a) (exists b))'
    )
    f = fb.insert
    f.foo = 42
    s = f.to_s
    assert_predicate(s.length, :positive?, s)
    assert_equal('[ foo: [42] ]', s)
  end

  def test_query_one
    fb = Factbase::Rules.new(Factbase.new, '(always)')
    f = fb.insert
    f.foo = 42
    assert_equal(1, fb.query('(agg (eq foo $v) (count))').one(v: 42))
  end

  def test_check_only_when_txn_is_closed
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    ok = false
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
        ok = true
      end
    end
    assert(ok)
  end

  def test_rollback_on_violation
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
      end
    end
    assert_equal(0, fb.size)
  end

  def test_in_combination_with_pre
    fb = Factbase::Rules.new(Factbase.new, '(when (exists a) (exists b))')
    fb =
      Factbase::Pre.new(fb) do |f|
        f.hello = 42
      end
    ok = false
    assert_raises(StandardError) do
      fb.txn do |fbt|
        f = fbt.insert
        f.a = 1
        f.c = 2
        ok = true
      end
    end
    assert(ok)
    assert_equal(0, fb.query('(eq hello $v)').each(v: 42).to_a.size)
  end
end
