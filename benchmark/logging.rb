#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'
require 'benchmark'

FileUtils.rm_rf FluQ.root.join("tmp/benchmark")
FileUtils.rm_rf FluQ.root.join("log/benchmark")

event   = ["some.tag", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"].to_msgpack
local   = FluQ::Reactor.new
central = FluQ::Reactor.new
output  = FluQ.root.join("log/benchmark/file.log")

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

sec = Benchmark.realtime do
  (0..10).map do
    Thread.new do |thread|
      socket = TCPSocket.new "127.0.0.1", "30303"
      3000.times { socket.write(event) }
      socket.close
    end
  end.each(&:join)
  sleep(0.1) until output.file? && output.size >= 1_830_000
end
puts "Completed in #{sec.round(1)}s"

sleep(3)