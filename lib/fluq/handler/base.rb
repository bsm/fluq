require 'digest/md5'

class FluQ::Handler::Base
  include FluQ::Mixins::Loggable

  # @return [String] handler type
  def self.type
    @type ||= name.split("::")[-1].downcase
  end

  # @attr_reader [String] name unique name
  attr_reader :name

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options
  # @option options [String] :name a (unique) handler identifier
  # @example
  #
  #   class MyHandler < FluQ::Handler::Base
  #   end
  #   MyHandler.new
  #
  def initialize(options = {})
    @config  = defaults.merge(options)
    @name    = config[:name] || self.class.type
  end

  # @param [Array<FluQ::Event>] events
  # @return [Array<FluQ::Event>] filtered events
  def filter(events)
    events
  end

  # @abstract callback, called on each event
  # @param [Array<FluQ::Event>] the event stream
  def on_events(events)
  end

  protected

    # Configuration defaults
    def defaults
      { timeout: 60 }
    end

end
