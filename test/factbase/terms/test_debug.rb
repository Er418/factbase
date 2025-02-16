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

# Debug test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDebug < Minitest::Test
  def test_traced
    t = Factbase::Term.new(Factbase.new, :traced, [Factbase::Term.new(Factbase.new, :defn, [:test_debug, 'self.to_s'])])
    assert_output("(traced (defn test_debug 'self.to_s')) -> true\n") do
      assert(t.evaluate(fact, []))
    end
  end

  def test_traced_raises
    e = assert_raises(StandardError) { Factbase::Term.new(Factbase.new, :traced, ['foo']).evaluate(fact, []) }
    assert_match(/A term expected, but 'foo' provided/, e.message)
  end

  def test_traced_raises_when_too_many_args
    e =
      assert_raises(StandardError) do
        Factbase::Term.new(
          Factbase.new, :traced,
          [Factbase::Term.new(Factbase.new, :defn, [:debug, 'self.to_s']), 'something']
        ).evaluate(fact, [])
      end
    assert_match(/Too many \(\d+\) operands for 'traced' \(\d+ expected\)/, e.message)
  end
end
