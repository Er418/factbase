# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
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
require 'json'
require 'nokogiri'
require 'yaml'
require_relative '../lib/factbase'

# Factbase main module test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestFactbase < Minitest::Test
  def test_simple_setting
    fb = Factbase.new
    fb.insert
    fb.insert.bar = 88
    found = 0
    fb.query('(exists bar)').each do |f|
      assert(42, f.bar.positive?)
      f.foo = 42
      assert_equal(42, f.foo)
      found += 1
    end
    assert_equal(1, found)
    assert_equal(2, fb.size)
  end

  def test_serialize_and_deserialize
    f1 = Factbase.new
    f2 = Factbase.new
    f1.insert.foo = 42
    Tempfile.open do |f|
      File.write(f.path, f1.export)
      f2.import(File.read(f.path))
    end
    assert_equal(1, f2.query('(eq foo 42)').each.to_a.count)
  end

  def test_empty_or_not
    fb = Factbase.new
    assert_equal(0, fb.size)
    fb.insert
    assert_equal(1, fb.size)
  end

  def test_run_txn
    fb = Factbase.new
    fb.insert.bar = 42
    assert_raises do
      fb.txn do
        fb.insert.foo = 42
        throw 'intentionally'
      end
    end
    assert_equal(1, fb.size)
  end
end
