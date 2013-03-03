#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'
require 'benchmark'

MultiJson.use :yajl
FileUtils.rm_rf FluQ.root.join("log/benchmark")

events = (1..100_000).map do
  FluQ::Event.new "a.b#{rand(4)}.c#{rand(100)}.d#{rand(100)}", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"
end

handler = FluQ::Handler::Log.new \
  path: "log/benchmark/%Y%m/%d/%H/%t.log",
  rewrite: lambda {|t| t.split(".")[1] }

puts "--> Started benchmark"
processed = Benchmark.realtime do
  num = 0
  events.each_slice(100) do |slice|
    handler.on_events(slice)
    num += slice.size
    if (num % 10_000).zero?
      puts "--> Processed : #{num}"
    end
  end
  handler = nil
  GC.start
end

puts "--> Processed : #{events.size} in #{processed.round(1)}s"
files   = Dir[FluQ.root.join("log/benchmark/**/*.log").to_s]
lines   = `cat #{files.join(' ')} | wc -l`.strip
puts "--> Written   : #{lines} lines"
