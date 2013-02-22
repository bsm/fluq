class FluQ::Handler::Forward < FluQ::Handler::Buffered

  attr_reader :urls

  # @see FluQ::Handler::Buffered#initialize
  # @option options [Array<String>] urls the URLs to delegate to
  # @raises [ArgumentError] when no URLs provided
  def initialize(*)
    super
    @urls = Array(config[:to]).map {|url| FluQ::URL.parse(url, protocols) }
    raise ArgumentError, "No `to` option given" if urls.empty?
  end

  # @see FluQ::Handler::Buffered#on_flush
  def on_flush(events)
    super
    do_forward events.map(&:encode).join
  end

  protected

    # @return [Array] supported protocols
    def protocols
      ["tcp", "unix"]
    end

    def connect(url)
      sock = case url.scheme
      when 'tcp'
        TCPSocket.new(url.host, url.port).tap do |s|
          s.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
        end
      when 'unix'
        UNIXSocket.new(url.path)
      end
      yield sock
    ensure
      sock.close if sock
    end

  private

    # Rescueable Exceptions
    FORWARD_EXCEPTIONS = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
      Errno::ENETUNREACH, Errno::ENETDOWN, Errno::EINVAL, Errno::ETIMEDOUT,
      IOError, EOFError
    ].freeze

    def do_forward(data)
      tried = [] # URLs we have tries
      begin
        url = (urls - tried).sample
        tried.push(url)
        connect(url) {|sock| sock.write(data) }
      rescue *FORWARD_EXCEPTIONS => e
        FluQ.logger.error "Forwarding failed to backend #{url}: #{e.message}"
        raise FluQ::Handler::Buffered::FlushError, "Forwarding failed. No backends available." if (urls - tried).empty? # No more URLs to try
        retry
      end
    end

end