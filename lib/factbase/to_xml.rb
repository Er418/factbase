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

require 'nokogiri'
require 'time'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to XML converter.
#
# This class helps converting an entire Factbase to YAML format, for example:
#
#  require 'factbase/to_xml'
#  fb = Factbase.new
#  puts Factbase::ToXML.new(fb).xml
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::ToXML
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into XML.
  # @return [String] The factbase in XML format
  def xml
    bytes = @fb.export
    meta = {
      version: Factbase::VERSION,
      size: bytes.size
    }
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.fb(meta) do
        Factbase::Flatten.new(Marshal.load(bytes), @sorter).it.each do |m|
          xml.f_ do
            m.sort.to_h.each do |k, vv|
              if vv.is_a?(Array)
                xml.send(:"#{k}_") do
                  vv.each do |v|
                    xml.send(:v, to_str(v), t: type_of(v))
                  end
                end
              else
                xml.send(:"#{k}_", to_str(vv), t: type_of(vv))
              end
            end
          end
        end
      end
    end.to_xml
  end

  private

  def to_str(val)
    if val.is_a?(Time)
      val.utc.iso8601
    else
      val.to_s
    end
  end

  def type_of(val)
    val.class.to_s[0]
  end
end
