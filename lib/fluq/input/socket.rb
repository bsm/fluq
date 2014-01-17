class FluQ::Input::Socket < FluQ::Input::Base
  MAXLEN = 16 * 1024

  # @attr_reader [URI] url the URL
  attr_reader :url

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
    @url = FluQ::URL.parse(config[:bind], protocols)

    async.run
  end

  # @return [String] descriptive name
  def name
    @name ||= "#{super} (#{@url})"
  end

  # Start the server
  def run
    super

    @server = case @url.scheme
    when 'tcp'
      TCPServer.new(@url.host, @url.port)
    when 'udp'
      UDPSocket.new.tap {|s| s.bind(@url.host, @url.port) }
    when 'unix'
      UNIXServer.open(@url.path)
    end

    case @url.scheme
    when 'udp'
      loop { process @server.recvfrom(MAXLEN)[0] }
    else
      loop { async.handle_connection @server.accept }
    end
  end

  # @return [Boolean] true when listening
  def listening?
    !!@server
  end

  protected

    # @return [Array] supported protocols
    def protocols
      ["tcp", "udp", "unix"]
    end

    # Handle a single connection
    def handle_connection(socket)
      loop do
        process socket.readpartial(MAXLEN)
      end
    rescue EOFError
    ensure
      socket.close
    end

    def before_terminate
      return unless @server

      @server.close
      File.delete @url.path if @url.scheme == "unix"
    end

end
