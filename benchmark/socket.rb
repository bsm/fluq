#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'

BATCH_SIZE = 100_000
BATCHES    = 50
ROOT       = FluQ.root.join("log/benchmark")
EVENT      = MessagePack.pack("k1" => "value", "k2" => "value", "k3" => "value")

FileUtils.rm_rf ROOT.to_s
FileUtils.mkdir_p ROOT.to_s
FluQ.logger.level = Logger::ERROR

puts "--> Preparing"
Thread.new do
  FluQ::Runner.run do |run|
    run.feed :test do |feed|
      feed.register FluQ::Handler::Noop
      feed.listen FluQ::Input::Socket, bind: "tcp://127.0.0.1:8765", format: :msgpack
    end
  end
end
BATCHES.times do |i|
  ROOT.join("batch.#{i}").open("wb:ASCII-8BIT") do |file|
    BATCH_SIZE.times { file.write(EVENT) }
  end
end

puts "--> Started benchmark"
2.times do
  start = Time.now
  BATCHES.times do |i|
    file = ROOT.join("batch.#{i}")
    system "nc 127.0.0.1 8765 < #{file}"
  end
  puts "--> Processed : #{BATCHES * BATCH_SIZE} in #{(Time.now - start).round(1)}s"
end
