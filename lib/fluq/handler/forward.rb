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

    # @return [Array] protocols supported protocols
    def protocols
      ["tcp", "uniq"]
    end

    def connect(url)
      socket = case url.scheme
      when 'tcp'
        Celluloid::IO::TCPSocket.new(url.host, url.port)
      when 'unix'
        Celluloid::IO::UNIXSocket.new(url.path)
      end
      yield socket
    ensure
      socket.close if socket
    end

  private

    def do_forward(data)
      tried = [] # URLs we have tries
      begin
        url = urls.shift
        tried.push(url)
        connect(url) {|sock| sock.write(data) }
      rescue Errno::ECONNREFUSED, IOError, EOFError => e
        FluQ.logger.error "Forwarding failed to backend #{url}: #{e.message}"
        raise FluQ::Handler::Buffered::FlushError, "Forwarding failed. No backends available." if urls.empty? # No more URLs to try
        retry
      ensure
        urls.push(*tried)
      end
    end

end