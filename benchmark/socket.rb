#!/usr/bin/env ruby

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler/setup'
require 'fluq'

BATCH_SIZE = 100_000
BATCHES    = 50
ROOT       = FluQ.root.join("log/benchmark")
EVENT      = FluQ::Event.new("a.b.c.d", Time.now.to_i, "k1" => "value", "k2" => "value", "k3" => "value").encode

FileUtils.rm_rf ROOT.to_s
FileUtils.mkdir_p ROOT.to_s

class FluQ::Handler::Counter < FluQ::Handler::Base
  attr_reader :count
  def initialize(*)
    super
    @count = 0
  end
  def on_events(events)
    @count += events.size
    EM.stop if @count >= BATCHES * BATCH_SIZE
  end
end

puts "--> Preparing"
BATCHES.times do |i|
  ROOT.join("batch.#{i}").open("wb:ASCII-8BIT") do |file|
    BATCH_SIZE.times { file.write(EVENT) }
  end
end

processed = 0
handler   = nil
start     = Time.now
FluQ::Reactor.run do |reactor|
  reactor.listen FluQ::Input::Socket, bind: "tcp://127.0.0.1:8765"
  handler = reactor.register FluQ::Handler::Counter

  sleep(0.1)
  start = Time.now
  puts "--> Started benchmark"
  BATCHES.times do |i|
    file = ROOT.join("batch.#{i}")
    spawn("nc 127.0.0.1 8765 < #{file}")
  end
end

puts "--> Accepted  : #{BATCHES * BATCH_SIZE} in #{(Time.now - start).round(1)}s"
puts "--> Processed : #{handler.count} events"
