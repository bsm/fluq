class FluQ::Input::Socket < FluQ::Input::Base

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
  end

  # @return [String] descriptive name
  def name
    @name ||= "#{super} (#{@url})"
  end

  # Start the server
  def run
    args = [self.class::Connection, self]
    case @url.scheme
    when 'tcp'
      EventMachine.start_server @url.host, @url.port, *args
    when 'udp'
      EventMachine.open_datagram_socket @url.host, @url.port, *args
    when 'unix'
      EventMachine.start_server @url.path, *args
    end
  end

  protected

    # @return [Array] supported protocols
    def protocols
      ["tcp", "udp", "unix"]
    end

end

%w'connection'.each do |name|
  require "fluq/input/socket/#{name}"
end
