class FluQ::Handler::Log < FluQ::Handler::Base

  class FilePool < TimedLRU

    def open(path)
      path = path.to_s
      self[path.to_s] ||= begin
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
    @pool      = FilePool.new max_size: config[:cache_max], ttl: config[:cache_ttl]
  end

  # @see FluQ::Handler::Base#on_events
  def on_events(events)
    partition(events).each {|path, slice| write(path, slice) }
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log",
        rewrite:  lambda {|tag| tag.gsub(".", "/") },
        convert:  lambda {|event| event.to_tsv },
        cache_max: 100,
        cache_ttl: 300
    end

    def write(path, slice, attepts = 0)
      io = @pool.open(path)
      slice.each do |event|
        io.write "#{@convert.call(event)}\n"
      end
    rescue IOError
      @pool.delete path.to_s
      (attepts+=1) < 3 ? retry : raise
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