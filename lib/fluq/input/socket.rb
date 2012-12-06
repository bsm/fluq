require 'celluloid/io'

class FluQ::Input::Socket < FluQ::Input::Base
  include Celluloid::IO

  # @attr_reader [URI] url the URL
  attr_reader :url

  # @attr_reader [Celluloid::IO::TCPServer|Celluloid::IO::UNIXServer] server the server
  attr_reader :server

  # Constructor.
  # @option options [String] :bind the URL to bind to
  # @raises [ArgumentError] when no bind URL provided
  # @raises [URI::InvalidURIError] if invalid URL is given
  # @example Launch a server
  #
  #   server = FluQ::Server.new(bind: "tcp://localhost:7654")
  #
  def initialize(options = {})
    url = options[:bind]
    raise ArgumentError, 'No URL to bind to provided, make sure you pass :bind option' unless url
    @url    = FluQ.parse_url(url)
    @pac    = MessagePack::Unpacker.new
    @server = case @url.scheme
    when 'tcp'
      TCPServer.new(@url.host, @url.port)
    when 'unix'
      UNIXServer.new(@url.path)
    end
    run!
  end

  # Destructor. Close connections.
  def finalize
    server.close if server
    FileUtils.rm_f(url.path) if url.scheme == "unix"
  end

  private

    # Start the server. Call `#run!` to launch as actor.
    def run
      loop { handle_connection! server.accept }
    end

    def handle_connection(socket)
      loop do
        @pac.feed_each(socket.readpartial(4096)) do |tag, timestamp, record|
          raise "STuPID ERROR" if tag == "b.c"
          FluQ.reactor.process(tag, timestamp, record)
        end
      end
    rescue EOFError
    end

end
