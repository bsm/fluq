#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'
require 'benchmark'

FileUtils.rm_rf FluQ.root.join("tmp/benchmark")
FileUtils.rm_rf FluQ.root.join("log/benchmark")

event   = FluQ::Event.new "some.tag", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"
packed  = event.encode
local   = FluQ::Reactor.new
central = FluQ::Reactor.new
output  = FluQ.root.join("log/benchmark/file.log")

QUEUE   = Queue.new
EVENTS  = 100_000
LIMIT   = (event.to_s.size + 1) * EVENTS

EVENTS.times { QUEUE.push(packed) }

local.listen FluQ::Input::Socket,
  bind: "tcp://127.0.0.1:30303"
local.register FluQ::Handler::Forward,
  to: "tcp://127.0.0.1:30304",
  buffer: "file",
  buffer_options: { path: "tmp/benchmark" },
  flush_rate: 10_000

central.listen FluQ::Input::Socket,
  bind: "tcp://127.0.0.1:30304"
central.register FluQ::Handler::Log,
  path: "log/benchmark/file.log"

dispatched = Benchmark.realtime do
  (0...5).map do
    Thread.new do |thread|
      socket = TCPSocket.new "127.0.0.1", "30303"
      while chunk = (QUEUE.pop(true) rescue nil)
        socket.write(chunk)
      end
      socket.close
    end
  end.each(&:join)
end
puts "Dispatched in #{dispatched.round(1)}s"

received = Benchmark.realtime do
  file_pool = central.handlers.values.first.send(:file_pool)
  output_handle = file_pool.handles.values.first
  sleep(1)
  sleep(0.1) while output_handle.atime > Time.now.to_i - 1 # no writes for 1 second - done
  file_pool.finalize
end
puts "Completed in #{(dispatched + received).round(1)}s"
puts "Used memory #{(`ps -o rss= -p #{Process.pid}`.to_f / 1024).round(2)} Mb, produced #{(output.size / 1024).round(2)} Mb output file"
