class FluQ::Buffer::File < FluQ::Buffer::Base

  # @attr_reader [FluQ::Buffer::File::Writer] writer
  attr_reader :writer

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @writer = FluQ::Buffer::File::Writer.new(config[:path], config[:max_size].to_i)

    # Archive all open files
    writer.glob :open do |path|
      writer.archive(path)
    end

    # Unreserve all reserved files
    writer.glob :reserved do |path|
      writer.unreserve(path)
    end
  end

  protected

    # @see FluQ::Buffer::Base#on_events
    def on_events(events)
      writer.write(events)
    end

    # @see FluQ::Buffer::Base#shift
    def shift
      writer.rotate
      shifted = 0
      writer.glob :closed do |path|
        reserved = writer.reserve(path)
        next unless reserved

        events = []
        reserved.open("r") do |io|
          events = FluQ::Event::Unpacker.new(io).to_a
        end
        shifted += events.size
        yield(events, path: reserved)
        break if shifted > 100_000
      end
    end

    # @see FluQ::Buffer::Base#commit
    def commit(events, opts = {})
      opts[:path].unlink if opts[:path]
    end

    # @see FluQ::Buffer::Base#revert
    def revert(events, opts = {})
      writer.unreserve(opts[:path]) if opts[:path]
    end

    def defaults
      super.merge path: "tmp/buffers/#{handler.name}", max_size: (128 * 1024 * 1024)
    end

end

%w'writer'.each do |name|
  require "fluq/buffer/file/#{name}"
end
