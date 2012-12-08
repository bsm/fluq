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

  # @param [Symbol<Pathname>] scope, either `:open` or `:closed`
  # @yield [Pathname] path matching scope
  def glob(scope, &block)
    Pathname.glob(scopes[scope], &block)
  end

  # @param [String] path path to archive
  # @return [Boolean] true if successful
  def archive(path)
    return false unless File.exist?(path)

    target = path.to_s.sub(/\.open$/, ".closed")
    FileUtils.mv path, target unless path == target
    true
  end

  def finalize
    current.close unless current.closed?
  end

  protected

    # Rotate the current file
    # @return [Boolean] true if successful
    def rotate
      return false if current.pos == 0

      path = current.path
      current.close
      archive(path)
    end

    # Writes event, call asynchronously as #write!
    # @param [FluQ::Event] event
    def write(event)
      binary = event.encode
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
      @scopes ||= { open: root.join("*.*.open").to_s, closed: root.join("*.*.closed").to_s }
    end

end
