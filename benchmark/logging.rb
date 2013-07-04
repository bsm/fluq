#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'
require 'benchmark'

ITER  = 1_000
SLICE = 1_000

FileUtils.rm_rf FluQ.root.join("log/benchmark")

events = (1..SLICE).map do
  FluQ::Event.new "a.b#{rand(4)}.c#{rand(10)}.d#{rand(100)}", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"
end

handler = FluQ::Handler::Log.new FluQ::Reactor.new,
  path: "log/benchmark/%Y%m/%d/%H/%t.log",
  rewrite: lambda {|t| t.split(".")[1, 2].join("-") }

puts "--> Started benchmark"
processed = Benchmark.realtime do
  num = 0
  ITER.times do
    handler.on_events(events)
    num += SLICE
    if (num % 10_000).zero?
      puts "--> Processed : #{num}"
    end
  end
end

puts "--> Processed : #{events.size} in #{processed.round(1)}s"
files   = Dir[FluQ.root.join("log/benchmark/**/*.log").to_s]
lines   = `cat #{files.join(' ')} | wc -l`.strip
puts "--> Fsynched  : #{lines} lines"
