require 'monitor'

class MockTCPServer
  extend MonitorMixin

  def self.listen(*ports)
    servers = ports.inject({}) {|res, port| res.update port => new(port) }
    yield(servers)
    servers.values.each(&:wait)
    servers.values.inject({}) {|res, s| res.update s.port => s.events }
  ensure
    servers.values.each(&:stop) if servers
  end

  attr_reader :port, :events

  def initialize(port)
    @port   = port
    @events = []
    @thread = start
    sleep(0.001) while @thread.alive? && !@thread[:listening]
  end

  def wait
    Timeout.timeout(0.05) do
      sleep(0.001) while @thread.alive?
    end
  rescue Timeout::Error
  end

  def stop
    @server.close unless @server.nil? || @server.closed?
    while @thread.alive?
      @thread.kill
      sleep(0.05)
    end
  end

  private

    def start
      Thread.new do
        @server = ::TCPServer.new("127.0.0.1", port)
        loop do
          Thread.current[:listening] = true
          @events += FluQ::Event::Unpacker.new(@server.accept).to_a
        end
      end
    end


end
