class Fluq::Handler::Log < Fluq::Handler::Base

  # @see Fluq::Handler::Base#initialize
  def initialize(*)
    super
    @full_path = Fluq.root.join(config[:path]).to_s.freeze
    @rewrite   = config[:rewrite]
    @convert   = config[:convert]
  end

  # @see Fluq::Handler::Base#on_event
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