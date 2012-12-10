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

    # Count records from orphaned files
    writer.glob :closed do |path|
      @pac.feed_each(path.read) { @size.update {|v| v += 1 } }
    end
  end

  protected

  # @return [FluQ::Buffer::File::Writer] thread-safe buffer writer
    def writer
      @writer ||= supervisor.actors.first
    end

    # @see FluQ::Buffer::Base#on_event
    def on_event(event)
      writer.async.write(event) # Async call
      @size.update {|v| v += 1 }
    end

    def shift
      writer.async.rotate
      writer.glob :closed do |path|
        events = []
        @pac.feed_each(path.read) {|e| events << e }
        yield(events, path)
      end
    end

    def commit(events, path)
      @size.update {|v| v -= events.size }
      path.unlink
    end

    def defaults
      super.merge path: "tmp/buffers/#{handler.name}", max_size: (128 * 1024 * 1024)
    end

end

%w'writer'.each do |name|
  require "fluq/buffer/file/#{name}"
end