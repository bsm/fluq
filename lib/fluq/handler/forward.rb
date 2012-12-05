class Fluq::Handler::Forward < Fluq::Handler::Buffered

  attr_reader :urls

  # @see Fluq::Handler::Buffered#initialize
  # @option options [Array<String>] urls the URLs to delegate to
  # @raises [ArgumentError] when no URLs provided
  def initialize(*)
    super
    @urls = Array(config[:urls]).map {|url| Fluq.parse_url(url) }
    raise ArgumentError, "No URLs configured" if urls.empty?
  end

  # @see Fluq::Handler::Buffered#on_flush
  def on_flush(events)
    do_forward events.map(&:encode).join
  rescue Errno::ECONNREFUSED
    raise Fluq::Handler::Buffered::FlushError.new("Forwarding failed. No backends available.")
  end

  protected

    def do_forward(data)
      tried = [] # URLs we have tries
      begin
        url = urls.shift
        tried.push(url)
        connect(url) {|sock| sock.write(data) }
      rescue Errno::ECONNREFUSED => e
        Fluq.logger.error "Forwarding failed to backend #{url}: #{e.message}"
        raise if urls.empty? # No more URLs to try
        retry
      ensure
        urls.push(*tried)
      end
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

end