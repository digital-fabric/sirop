# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'benchmark-ips'
end

require 'benchmark/ips'

def gen_v_plain(*conds)
  ->(v) {
    conds.each { raise unless it === v }
  }
end

# string interpolation
def gen_v_si(*conds)
  eval([
    "->(v) { ",
    *(conds.map { "raise unless (#{it.inspect}) === v;" }),
    "true }"
  ].join)
end

# v_plain = gen_v_plain(Integer, 1..10)
# v_si    = gen_v_si(Integer, 1..10)
# v = 1

v_plain = gen_v_plain(String, /foo/)
v_si    = gen_v_si(String, /foo/)
v = 'foobar'

Benchmark.ips do |x|
  # x.config(:time => 5, :warmup => 2)
  x.report("plain")                { v_plain.(v) }
  x.report("string-interpolation") { v_si.(v) }
  x.compare!
end
