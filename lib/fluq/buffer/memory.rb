class Fluq::Buffer::Memory < Fluq::Buffer::Base
  extend Forwardable

  attr_reader :store
  def_delegators :store, :size

  # @see Fluq::Buffer::Base#initialize
  def initialize(*)
    super
    @store = []
  end

  protected

    def on_event(event)
      store.push(event)
    end

    def shift
      yield(store.shift(10_000))
    end

    def revert(buffer)
      store.unshift(buffer)
    end

end