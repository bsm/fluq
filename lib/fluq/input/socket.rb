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
  #   server = FluQ::Server.new(reactor, bind: "tcp://localhost:7654")
  #
  def initialize(*)
    super

    raise ArgumentError, 'No URL to bind to provided, make sure you pass :bind option' unless config[:bind]
    @url    = FluQ::URL.parse(config[:bind], protocols)
    @server = case @url.scheme
    when 'tcp'
      TCPServer.new(@url.host, @url.port).tap do |s|
        s.to_io.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        s.to_io.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      end
    when 'unix'
      UNIXServer.new(@url.path)
    end
    async.run
  end

  # Destructor. Close connections.
  def finalize
    server.close if server
    FileUtils.rm_f(url.path) if url.scheme == "unix"
  end

  # Start the server.
  def run
    loop { async.handle_connection server.accept }
  end

  # Handle an incoming connection
  def handle_connection(socket)
    FluQ::Event::Unpacker.new(socket).each_slice(100) do |slice|
      reactor.process(slice)
    end
  end

  protected

    # @return [Array] supported protocols
    def protocols
      ["tcp", "unix"]
    end

end
