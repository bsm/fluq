class FluQ::Event::Unpacker < MessagePack::Unpacker
  include Enumerable

  # @yield over events
  # @yieldparam [Event] event
  def each
    super do |tag, timestamp, record|
      yield FluQ::Event.new(tag, timestamp, record)
    end
  rescue EOFError
  end

  # Iterates over events in `data`
  # @param [String] data raw data
  # @yieldparam [Event] event
  def feed_each(data)
    super do |tag, timestamp, record|
      yield FluQ::Event.new(tag, timestamp, record)
    end
  end

  # Like #feed_each, just in slices of `per_slice`
  # @param [String] data raw data
  # @param [Integer] per_slice items per slice
  # @yieldparam [Array<Event>] events
  def feed_slice(data, per_slice, &block)
    slice = []
    feed_each(data) do |event|
      slice << event
      if slice.size >= per_slice
        block.call(slice)
        slice = []
      end
    end
    block.call(slice)
  end

  private

    def process_slice(slice, &block)
      block.call(slice)
      nil
    ensure
      slice.clear
    end

end
