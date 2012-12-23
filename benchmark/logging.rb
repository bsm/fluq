#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'benchmark'

EVENTS  = 1_000_000
OUTPUT  = "log/benchmark/file.log"

# Fork worker reactor
worker = fork do
  require 'fluq'
  FileUtils.rm_rf FluQ.root.join("tmp/benchmark")

  reactor = FluQ::Reactor.new
  reactor.listen FluQ::Input::Socket,
    bind: "tcp://127.0.0.1:30303"
  reactor.register FluQ::Handler::Forward,
    to: "tcp://127.0.0.1:30304",
    buffer: "file",
    buffer_options: { path: "tmp/benchmark" },
    flush_interval: 2,
    flush_rate: 10_000
  sleep
end

# Fork collector reactor
collector = fork do
  require 'fluq'
  FileUtils.rm_rf FluQ.root.join("log/benchmark")
  reactor = FluQ::Reactor.new
  reactor.listen FluQ::Input::Socket,
    bind: "tcp://127.0.0.1:30304"
  reactor.register FluQ::Handler::Log,
    path: OUTPUT
  sleep
end

# Wait for reactors to start
sleep(1)
require 'fluq'

output  = FluQ.root.join(OUTPUT)
counter = lambda { output.file? ? `cat #{output} | wc -l`.to_i : 0 }

# Fork client process
client  = fork do
  queue  = Queue.new
  event  = FluQ::Event.new "some.tag", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value"
  packed = event.encode
  EVENTS.times { queue.push(packed) }

  (0...5).map do
    Thread.new do
      socket = TCPSocket.new "127.0.0.1", "30303"
      while chunk = (queue.pop(true) rescue nil)
        socket.write(chunk)
      end
      socket.close
    end
  end.each(&:join)
end

dispatched  = Benchmark.realtime do
  Process.wait(client)
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
