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
require_relative '../../lib/factbase/fact'

# Fact test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestFact < Minitest::Test
  def test_injects_data_correctly
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    f.foo = 1
    f.bar = 2
    f.bar = 3
    assert_equal(2, map.size)
    assert_equal([1], map['foo'])
    assert_equal([2, 3], map['bar'])
  end

  def test_simple_resetting
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    f.foo = 42
    assert_equal(42, f.foo, f.to_s)
    f.foo = 256
    assert_equal(42, f.foo, f.to_s)
    assert_equal([42, 256], f['foo'], f.to_s)
  end

  def test_keeps_values_unique
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    f.foo = 42
    f.foo = 'Hello'
    assert_equal(2, map['foo'].size)
    f.foo = 42
    assert_equal(2, map['foo'].size)
  end

  def test_fails_when_empty
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    assert_raises(StandardError) do
      f.something
    end
  end

  def test_fails_when_setting_nil
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    assert_raises(StandardError) do
      f.foo = nil
    end
  end

  def test_fails_when_setting_empty
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    assert_raises(StandardError) do
      f.foo = ''
    end
  end

  def test_fails_when_not_found
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    f.first = 42
    assert_raises(StandardError) do
      f.second
    end
  end

  def test_set_by_name
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    f.send(:_foo_bar=, 42)
    assert_equal(42, f._foo_bar, f.to_s)
  end

  def test_set_twice_same_value
    map = {}
    f = Factbase::Fact.new(Factbase.new, Mutex.new, map)
    f.foo = 42
    f.foo = 42
    assert_equal([42], map['foo'])
  end

  def test_time_in_utc
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    t = Time.now
    f.foo = t
    assert_equal(t.utc, f.foo)
    assert_equal(t.utc.to_s, f.foo.to_s)
  end

  def test_some_names_are_prohibited
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    assert_raises(StandardError) { f.to_s = 42 }
    assert_raises(StandardError) { f.class = 42 }
  end

  def test_get_all_properties
    f = Factbase::Fact.new(Factbase.new, Mutex.new, {})
    f.foo = 42
    assert_includes(f.all_properties, 'foo')
  end
end
