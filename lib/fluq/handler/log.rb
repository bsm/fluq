require 'rufus/lru'

class FluQ::Handler::Log < FluQ::Handler::Base

  class FilePool < Rufus::Lru::SynchronizedHash

    def open(path)
      path = path.to_s
      self[path] ||= begin
        FileUtils.mkdir_p File.dirname(path)
        file = File.open(path, "a+")
        file.autoclose = true
        file
      end
    end

  end

  # @attr_reader [FluQ::Handler::Log::FilePool] file pool
  attr_reader :pool

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @full_path = FluQ.root.join(config[:path]).to_s.freeze
    @rewrite   = config[:rewrite]
    @convert   = config[:convert]
    @pool      = FilePool.new(config[:file_max])
  end

  # @see FluQ::Handler::Base#on_events
  def on_events(events)
    partition(events).each do |path, slice|
      io = @pool.open(path)
      slice.each do |event|
        io.write "#{@convert.call(event)}\n"
      end
    end
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log",
        rewrite:  lambda {|tag| tag.gsub(".", "/") },
        convert:  lambda {|event| event.to_s },
        file_max: 1_000
    end

    def open(path)
      FileUtils.mkdir_p File.dirname(path)
      file = File.open(path, "a+")
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