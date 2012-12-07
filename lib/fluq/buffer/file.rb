class FluQ::Buffer::File < FluQ::Buffer::Base
  FILE_LIMIT = 128 * 1024 * 1024 # 128M

  # @attr_reader [Pathname] buffer root
  attr_reader :root

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @pac  = MessagePack::Unpacker.new
    @root = FluQ.root.join(config[:path])

    # Ensure the directory exists
    FileUtils.mkdir_p(root)

    # Archive all open files
    glob(:open).each do |path|
      archive(path)
    end

    # Count records from orphaned files
    glob(:closed).each do |path|
      @pac.feed_each(path.read) { @size.update {|v| v += 1 } }
    end
  end

  # Rotate the current file
  def rotate!
    previous = current.path
    current.close
    archive(previous)
  end
  alias_method :finalize, :rotate!

  # @param [Symbol<Pathname>] scope, either `:open` or `:closed`
  # @return [Array<Pathname>] scoped paths
  def glob(scope)
    Pathname.glob(scopes[scope]).sort
  end

  protected

    # @see FluQ::Buffer::Base#on_event
    def on_event(event)
      current.write(event.encode)
      @size.update {|v| v += 1 }
      rotate! if current.pos > FILE_LIMIT
    end

    # @return [Hash] file scopes
    def scopes
      @scopes ||= { open: root.join("*.*.open").to_s, closed: root.join("*.*.closed").to_s }
    end

    # @return [Pathname] current file
    def current
      @current = open_file if @current.nil? || @current.closed?
      @current
    end

    def shift
      rotate! unless current.pos == 0
      glob(:closed).each do |path|
        events = []
        @pac.feed_each(path.read) {|e| events << e }
        yield(events, path: path)
      end
    end

    def commit(events, opts = {})
      @size.update {|v| v -= events.size }
      opts[:path].unlink if opts[:path]
    end

    # @return [File] a newly opened file
    def open_file
      path = nil
      until path && !path.exist?
        time = Time.now.utc.strftime("%Y%m%d%H")
        hash = SecureRandom.hex(4)
        path = root.join("#{time}.#{hash}.open")
      end
      File.open(path, "wb")
    end

    # Archive the current file
    def archive(path)
      FileUtils.mv path, path.sub(/\.open$/, ".closed")
    end

    def defaults
      super.merge path: "tmp/buffers/#{handler.name}"
    end

end
