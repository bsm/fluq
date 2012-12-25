require 'digest/md5'

class FluQ::Handler::Base
  include FluQ::Mixins::Loggable

  # @return [String] handler type
  def self.type
    @type ||= name.split("::")[-1].downcase
  end

  # @attr_reader [FluQ::Reactor] reactor reference
  attr_reader :reactor

  # @attr_reader [String] name unique name
  attr_reader :name

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options
  # @option options [String] :name a (unique) handler identifier
  # @option options [String] :pattern tag pattern to match
  # @example
  #
  #   class MyHandler < FluQ::Handler::Base
  #   end
  #   MyHandler.new(pattern: "visits.*")
  #
  def initialize(reactor, options = {})
    @reactor = reactor
    @config  = defaults.merge(options)
    @name    = config[:name] || generate_name
  end

  # @return [Boolean] true if tag matches
  def match?(tag)
    File.fnmatch? config[:pattern], tag.to_s
  end

  # @param [Array<FluQ::Event>] events
  # @return [Array<FluQ::Event>] matching events
  def select(events)
    events.select {|e| match?(e.tag) }
  end

  # @abstract callback, called on each event
  # @param [Array<FluQ::Event>] the event stream
  def on_events(events)
  end

  protected

    # Configuration defaults
    def defaults
      { pattern: "*" }
    end

    # @return [String] generated name
    def generate_name
      suffix = [Digest::MD5.digest(config[:pattern])].pack("m0").tr('+/=lIO0', 'pqrsxyz')[0,6]
      [self.class.type, suffix].join("-")
    end

end
