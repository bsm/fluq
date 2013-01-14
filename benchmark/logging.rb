#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'benchmark'
require 'tempfile'
require 'fluq'

FileUtils.rm_rf FluQ.root.join("tmp/benchmark")
FileUtils.rm_rf FluQ.root.join("log/benchmark")

EVENTS = 1_000_000
OUTPUT = "log/benchmark/file.log"
EVENT  = FluQ::Event.new "some.tag", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"
PACKED = EVENT.encode
SOURCE = Tempfile.new("fluq.bm").path

File.open(SOURCE, "wb") do |f|
  EVENTS.times { f << PACKED }
end

# Fork worker reactor
worker = fork do
  FluQ::Reactor.run do |reactor|
    reactor.listen FluQ::Input::Socket,
      bind: "tcp://127.0.0.1:30303"
    reactor.register FluQ::Handler::Forward,
      to: "tcp://127.0.0.1:30304",
      buffer: "file",
      buffer_options: { path: "tmp/benchmark" },
      flush_interval: 2,
      flush_rate: 10_000
  end
end

# Fork collector reactor
collector = fork do
  FluQ::Reactor.run do |reactor|
    reactor.listen FluQ::Input::Socket,
      bind: "tcp://127.0.0.1:30304"
    reactor.register FluQ::Handler::Log,
      path: OUTPUT
  end
end

# Wait for reactors to start
sleep(1)

output  = FluQ.root.join(OUTPUT)
counter = lambda { output.file? ? `cat #{output} | wc -l`.to_i : 0 }

dispatched  = Benchmark.realtime do
  `cat #{SOURCE} | nc 127.0.0.1 30303`
  # Process.wait(client)
end

received = Benchmark.realtime do
  while (count = counter.call) < EVENTS
    FluQ.logger.debug "Processed #{count} events"
    sleep(1)
  end
end

puts "   Dispatched in : #{dispatched.round(1)}s"
puts "   Completed in  : #{(dispatched + received).round(1)}s"
puts "   Worker RSS    : #{(`ps -o rss= -p #{worker}`.to_f / 1024).round(1)}M"
puts "   Collector RSS : #{(`ps -o rss= -p #{collector}`.to_f / 1024).round(1)}M"
puts "   Processed     : #{counter.call} events"

Process.kill(:TERM, worker)
Process.kill(:TERM, collector)
