# Thread-safe writer
class FluQ::Buffer::File::Writer
  include Celluloid

  # @attr_reader [Pathname] root the root path
  attr_reader :root

  # @attr_reader [Integer] limit the buffer file limit
  attr_reader :limit

  # Constructor
  # @param [String] path the path string with patterns
  # @param [Integer] limit the buffer file limit
  def initialize(path, limit)
    @root  = FluQ.root.join(path)
    @limit = limit

    # Ensure the directory exists
    FileUtils.mkdir_p(root)
  end

  # @param [Symbol<Pathname>] scope, either `:open`, `:closed` or `:reserved`
  # @yield [Pathname] path matching scope
  def glob(scope, &block)
    Pathname.glob(scopes[scope], &block)
  end

  # @param [Pathname] path path to archive
  # @return [Pathname, NilClass] the archived file or nil
  def archive(path)
    return unless path.to_s.match(/\.open$/)

    target = Pathname.new path.to_s.sub(/\.open$/, ".closed")
    path.rename(target.to_s) unless path == target
    target
  rescue Errno::ENOENT
  end

  # @param [Pathname] path path to file
  # @return [Pathname,NilClass] the reserved file or false
  def reserve(path)
    return unless path.to_s.match(/\.closed$/)

    target = Pathname.new "#{path}.#{SecureRandom.hex(6)}"
    path.rename(target.to_s)
    target
  rescue Errno::ENOENT
  end

  # @param [Pathname] path path to file
  # @return [Pathname,NilClass] the closed file or false
  def unreserve(path)
    return unless path.to_s.match(/\.closed.\w+$/)

    target = Pathname.new path.to_s.sub(/\.closed.\w+$/, '.closed')
    path.rename(target.to_s)
    target
  rescue Errno::ENOENT
  end

  def finalize
    current.close unless current.closed?
  end

  # Rotate the current file
  # @return [Boolean] true if successful
  def rotate
    return false if current.pos == 0

    path = current.path
    current.close
    !!archive(Pathname.new(path))
  end

  # Writes events, can be called asynchronously
  # @param [Array<FluQ::Event>] events
  def write(events)
    binary = events.map(&:encode).join
    rotate if current.pos + binary.bytesize > limit
    current.write(binary)
  end

  # @attr_reader [File] the current buffer
  def current
    @current = new_file if @current.nil? || @current.closed?
    @current
  end

  private

    # @return [File] a newly opened file
    def new_file
      path = nil
      until path && !path.exist?
        time = Time.now.utc.strftime("%Y%m%d%H")
        hash = SecureRandom.hex(4)
        path = root.join("#{time}.#{hash}.open")
      end
      file = File.open(path, "wb")
      file.sync = true
      file
    end

    # @return [Hash] file scopes
    def scopes
      @scopes ||= { open: root.join("*.*.open").to_s, closed: root.join("*.*.closed").to_s, reserved: root.join("*.*.closed.*").to_s }
    end

end
