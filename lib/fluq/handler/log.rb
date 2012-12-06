require 'zlib'

class FluQ::Handler::Log < FluQ::Handler::Base

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @full_path = FluQ.root.join(config[:path]).to_s.freeze
    @gzip      = !!(@full_path =~ /\.gz$/)
    @rewrite   = config[:rewrite]
    @convert   = config[:convert]
  end

  # @see FluQ::Handler::Base#on_event
  def on_event(event)
    tag  = @rewrite.call(event.tag)
    path = event.time.strftime(@full_path.gsub("%t", tag))

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "a+") do |file|
      write(file, event)
    end
  end

  protected

    def write(io, event)
      io = Zlib::GzipWriter.new(io) if @gzip
      io.puts(@convert.call(event))
    ensure
      io.close
    end

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log.gz",
        rewrite: lambda {|tag| tag.gsub(".", "/") },
        convert: lambda {|event| event.to_s }
    end

end