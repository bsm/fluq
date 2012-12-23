class FluQ::Buffer::File < FluQ::Buffer::Base

  # @attr_reader [Celluloid::SupervisionGroup] supervisor
  attr_reader :supervisor

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
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
      path.open("r") do |io|
        @size.update {|v| v + FluQ::Event::Unpacker.new(io).count }
      end
    end
  end

  protected

    # @return [FluQ::Buffer::File::Writer] thread-safe buffer writer
    def writer
      @writer ||= supervisor.actors.first
    end

    # @see FluQ::Buffer::Base#on_events
    def on_events(events)
      writer.write(events)
    end

    # @see FluQ::Buffer::Base#shift
    def shift
      writer.async.rotate
      writer.glob :closed do |path|
        reserved = writer.reserve(path)
        next unless reserved

        events = []
        reserved.open("r") do |io|
          events = FluQ::Event::Unpacker.new(io).to_a
        end
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
