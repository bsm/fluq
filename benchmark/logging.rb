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
  (0...20).map do
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
  sleep(0.1) until output.file? && output.size >= LIMIT
end
puts "Completed in #{(dispatched + received).round(1)}s"

sleep(1)