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
require_relative '../../lib/factbase/tee'
require_relative '../../lib/factbase/fact'

# Tee test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTee < Minitest::Test
  def test_two_facts
    prim = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    prim.foo = 42
    upper = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_equal(42, t.foo)
    assert_equal([13], t['$bar'])
  end

  def test_all_properties
    prim = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    prim.foo = 42
    upper = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_includes(t.all_properties, 'foo')
    assert_includes(t.all_properties, 'bar')
  end

  def test_recursively
    map = {}
    prim = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    prim.foo = 42
    t = Factbase::Tee.new(nil, { 'bar' => 7 })
    assert_equal(7, t['$bar'])
    t = Factbase::Tee.new(prim, t)
    assert_equal(7, t['$bar'])
  end

  def test_prints_to_string
    prim = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    prim.foo = 42
    upper = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    upper.bar = 13
    t = Factbase::Tee.new(prim, upper)
    assert_equal('[ foo: [42] ]', t.to_s)
  end
end
