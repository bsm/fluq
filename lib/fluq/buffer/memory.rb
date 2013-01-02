class FluQ::Buffer::Memory < FluQ::Buffer::Base

  attr_reader :store

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @store = []
  end

  protected

    def on_events(events)
      store.concat(events)
    end

    def shift
      yield(store.shift(store.size), {})
    end

    def revert(buffer, *)
      store.unshift(buffer)
    end

end