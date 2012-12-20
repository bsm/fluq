class FluQ::Handler::Log::FilePool
  Handle = Struct.new(:io, :atime)

  attr_reader :handles, :mode, :ttl, :gzip

  def initialize(options = {})
    @handles = {}
    @mode    = options[:mode] || 'a+'
    @ttl     = options[:ttl] || 60
    @gzip    = !!options[:gzip]
    Kernel.at_exit(&method(:finalize))
  end

  # @param [String] path
  # @return [IO] IO object
  def get(path)
    (find(path) || open(path)).io
  end

  def close_stale
    stale_paths.each do |path|
      close(path)
    end
  end

  def finalize
    handles.keys.each do |path|
      close(path)
    end
  end

  protected

    def find(path)
      handles[path].tap do |handle|
        handle.atime = Time.now.to_i if handle
      end
    end

    def open(path)
      FileUtils.mkdir_p(File.dirname(path))
      io = File.open(path, mode)
      io = Zlib::GzipWriter.new(io) if gzip
      handles[path] = Handle.new(io, Time.now.to_i)
    end

    def close(path)
      handle = handles.delete(path)
      handle.io.flush
      handle.io.close
    end

    def stale_paths
      min = Time.now.to_i - ttl
      handles.select do |path, handle|
        handle.atime < min
      end.map(&:first)
    end

end
