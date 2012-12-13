class FluQ::Buffer::Memory < FluQ::Buffer::Base

  attr_reader :store

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @store = []
  end

  protected

    def on_event(event)
      store.push(event)
    end

    def shift
      yield(store.shift(rate), {})
    end

    def revert(buffer, *)
      store.unshift(buffer)
    end

end