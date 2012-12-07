class FluQ::Buffer::Memory < FluQ::Buffer::Base
  extend Forwardable

  attr_reader :store
  def_delegators :store, :size

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
      yield(store.shift(10_000), {})
    end

    def revert(buffer, *)
      store.unshift(buffer)
    end

end