class Fluq::Buffer::Memory < Fluq::Buffer::Base
  extend Forwardable

  attr_reader :events
  def_delegators :events, :size, :push

  # @see Fluq::Buffer::Base#initialize
  def initialize(*)
    super
    @events = []
  end

  protected

    def shift
      yield(events.shift(10_000))
    end

    def revert(buffer)
      events.unshift(buffer)
    end

end