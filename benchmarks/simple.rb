#!/usr/bin/env ruby
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

require 'benchmark'
require 'time'
require_relative '../lib/factbase'

def insert(fb, total)
  time =
    Benchmark.measure do
      total.times do |i|
        fact = fb.insert
        fact.id = i
        fact.title = "Object Thinking #{i}"
        fact.time = Time.now.iso8601
        fact.cost = rand(1..100)
        fact.foo = rand(0.0..100.0).round(3)
        fact.bar = rand(100..300)
        fact.seenBy = "User#{i}" if i.even?
        fact.zzz = "Extra#{i}" if (i % 10).zero?
      end
    end
  {
    title: '`fb.insert()`',
    time: time.real,
    details: "Inserted #{total} facts"
  }
end

def query(fb, query)
  total = 0
  runs = 10
  time =
    Benchmark.measure do
      runs.times do
        total = fb.query(query).each.to_a.size
      end
    end
  {
    title: "`#{query}`",
    time: (time.real / runs).round(6),
    details: "Found #{total} fact(s)"
  }
end

def impex(fb)
  size = 0
  time =
    Benchmark.measure do
      bin = fb.export
      size = bin.size
      fb2 = Factbase.new
      fb2.import(bin)
    end
  {
    title: '`.export()` + `.import()`',
    time: time.real,
    details: "#{size} bytes"
  }
end

fb = Factbase.new
rows = [
  insert(fb, 100_000),
  query(fb, '(gt time \'2024-03-23T03:21:43Z\')'),
  query(fb, '(gt cost 50)'),
  query(fb, '(eq title \'Object Thinking 5000\')'),
  query(fb, '(and (eq foo 42.998) (or (gt bar 200) (absent zzz)))'),
  query(fb, '(eq id (agg (always) (max id)))'),
  query(fb, '(join "c<=cost,b<=bar" (eq id (agg (always) (max id))))'),
  impex(fb)
].map { |r| "| #{r[:title]} | #{format('%0.3f', r[:time])} | #{r[:details]} |" }

puts '| Action | Seconds | Details |'
puts '| --- | --: | --- |'
rows.each { |row| puts row }
