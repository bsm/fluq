require 'uri'
require 'msgpack'
require 'celluloid/io'

class Fluq::Server
  include Celluloid::IO

  # @attr_reader [URI] url the URL
  attr_reader :url

  # @attr_reader [Celluloid::IO::TCPServer|Celluloid::IO::UNIXServer] server the server
  attr_reader :server

  # Constructor.
  # @param [String] url the URL to bind to
  # @raises [URI::InvalidURIError] if invalid URL is given
  # @example Launch a server
  #   server = Fluq::Server.new("tcp://localhost:7654")
  #   server.run!
  def initialize(url)
    @url      = Fluq.parse_url(url)
    @handlers = []
    @server   = case @url.scheme
    when "tcp"
      TCPServer.new(@url.host, @url.port)
    when "unix"
      UNIXServer.new(@url.path)
    end
  end

  # Register a new handler
  # @param [Fluq::Handler::Base] handler the handler instance
  def register(handler)
    @handlers.push(handler)
  end

  # Destructor. Close connections.
  def finalize
    @server.close if @server
  end

  # Start the server. Call `#run!` to launch as actor.
  def run
    loop { handle_connection! @server.accept }
  end

  private

    def handle_connection(socket)
      loop do
        @unpacker.feed_each(socket.readpartial(4096)) do |tag, timestamp, record|
          event = Fluq::Event.parse(tag, timestamp, record)
          @handlers.each do |handler|
            handler.on_event(event.dup) if handler.match?(event.tag)
          end if event
        end
      end
    rescue EOFError
    end

end

