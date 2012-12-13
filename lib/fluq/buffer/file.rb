class FluQ::Buffer::File < FluQ::Buffer::Base

  # @attr_reader [Celluloid::SupervisionGroup] supervisor
  attr_reader :supervisor

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @pac = MessagePack::Unpacker.new
    @supervisor = FluQ::Buffer::File::Writer.supervise(config[:path], config[:max_size].to_i)

    # Archive all open files
    writer.glob :open do |path|
      writer.archive(path)
    end

    # Unreserve all reserved files
    writer.glob :reserved do |path|
      writer.unreserve(path)
    end

    # Count records from orphaned files
    writer.glob :closed do |path|
      count = 0
      @pac.feed_each(path.read) {|*| count += 1 }
      @size.update {|v| v += count }
    end
  end

  protected

    # @return [FluQ::Buffer::File::Writer] thread-safe buffer writer
    def writer
      @writer ||= supervisor.actors.first
    end

    # @see FluQ::Buffer::Base#on_event
    def on_event(event)
      writer.async.write(event)
    end

    # @see FluQ::Buffer::Base#shift
    def shift
      writer.async.rotate
      writer.glob :closed do |path|
        reserved = writer.reserve(path)
        next unless reserved

        events = []
        @pac.feed_each(reserved.read) {|a| events << FluQ::Event.new(*a) }
        yield(events, path: reserved)
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
