require 'zlib'

class FluQ::Handler::Log < FluQ::Handler::Base

  attr_reader :io_cache
  IOHandle = Struct.new(:io, :ts)

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @full_path = FluQ.root.join(config[:path]).to_s.freeze
    @gzip      = !!(@full_path =~ /\.gz$/)
    @rewrite   = config[:rewrite]
    @convert   = config[:convert]
    @io_cache  = {}

    FluQ.timers.every(60) { expire_cache! }
    Kernel.at_exit { finalize }
  end

  # @see FluQ::Handler::Base#on_event
  def on_event(event)
    tag  = @rewrite.call(event.tag)
    path = event.time.strftime(@full_path.gsub("%t", tag))

    checkout(path) do |io|
      io.write "#{@convert.call(event)}\n"
    end
  end

  def finalize
    expire_cache!(0)
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log.gz",
        rewrite: lambda {|tag| tag.gsub(".", "/") },
        convert: lambda {|event| event.to_s }
    end

  private

    def expire_cache!(max_age = 60)
      io_cache.delete_if do |_, handle|
        stale = (handle.ts <= Time.now.to_i - max_age)
        handle.io.close if stale
        stale
      end
    end

    def checkout(path)
      io_cache[path] = open(path) if io_cache[path].nil? || io_cache[path].io.closed?
      yield io_cache[path].io
      io_cache[path].ts = Time.now.to_i
    end

    def open(path)
      FileUtils.mkdir_p(File.dirname(path))
      io = File.open(path, "a+")
      io = Zlib::GzipWriter.new(io) if @gzip
      IOHandle.new(io, Time.now.to_i)
    end

end