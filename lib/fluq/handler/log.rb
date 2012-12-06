class FluQ::Handler::Log < FluQ::Handler::Base

  # @see FluQ::Handler::Base#initialize
  def initialize(*)
    super
    @full_path = FluQ.root.join(config[:path]).to_s.freeze
    @rewrite   = config[:rewrite]
    @convert   = config[:convert]
  end

  # @see FluQ::Handler::Base#on_event
  def on_event(event)
    tag  = @rewrite.call(event.tag)
    path = event.time.strftime(@full_path.gsub("%t", tag))

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "a+") do |file|
      file.puts @convert.call(event)
    end
  end

  protected

    # Configuration defaults
    def defaults
      super.merge \
        path: "log/raw/%t/%Y%m%d/%H.log",
        rewrite: lambda {|tag| tag.gsub(".", "/") },
        convert: lambda {|event| event.to_s }
    end

end