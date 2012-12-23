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

  # @see FluQ::Handler::Base#on_events
  def on_events(events)
    partition(events).each do |path, slice|
      open(path) do |io|
        slice.each do |event|
          io.write "#{@convert.call(event)}\n"
        end
      end
    end
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log.gz",
        rewrite: lambda {|tag| tag.gsub(".", "/") },
        convert: lambda {|event| event.to_s }
    end

    def open(path)
      FileUtils.mkdir_p File.dirname(path)
      file = File.open(path, "a+")
      file = Zlib::GzipWriter.new(file) if @gzip
      yield file
    ensure
      file.close if file
    end

    def partition(events)
      paths = {}
      events.each do |event|
        tag  = @rewrite.call(event.tag)
        path = event.time.strftime(@full_path.gsub("%t", tag))
        paths[path] ||= []
        paths[path]  << event
      end
      paths
    end

end