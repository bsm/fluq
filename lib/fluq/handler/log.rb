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

    io = file_pool.get(path)
    io.puts(@convert.call(event))
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log.gz",
        rewrite: lambda {|tag| tag.gsub(".", "/") },
        convert: lambda {|event| event.to_s }
    end

    def file_pool
      @file_pool ||= FluQ::Handler::Log::FilePool.new(gzip: @gzip)
    end

end
