require 'digest/md5'

class FluQ::Handler::Base
  include FluQ::Mixins::Loggable

  # @return [String] handler type
  def self.type
    @type ||= name.split("::")[-1].downcase
  end

  # @attr_reader [FluQ::Reactor] reactor
  attr_reader :reactor

  # @attr_reader [String] name unique name
  attr_reader :name

  # @attr_reader [Hash] config
  attr_reader :config

  # @attr_reader [Regexp] pattern
  attr_reader :pattern

  # @param [Hash] options
  # @option options [String] :name a (unique) handler identifier
  # @option options [String] :pattern tag pattern to match
  # @example
  #
  #   class MyHandler < FluQ::Handler::Base
  #   end
  #   MyHandler.new(reactor, pattern: "visits.*")
  #
  def initialize(reactor, options = {})
    @reactor = reactor
    @config  = defaults.merge(options)
    @name    = config[:name] || generate_name
    @pattern = generate_pattern
  end

  # @return [Boolean] true if event matches
  def match?(event)
    !!(pattern =~ event.tag)
  end

  # @param [Array<FluQ::Event>] events
  # @return [Array<FluQ::Event>] matching events
  def select(events)
    events.select {|e| match?(e) }
  end

  # @abstract callback, called on each event
  # @param [Array<FluQ::Event>] the event stream
  def on_events(events)
  end

  protected

    # Configuration defaults
    def defaults
      { pattern: /./, timeout: 60 }
    end

    # @return [String] generated name
    def generate_name
      suffix = [Digest::MD5.digest(config[:pattern].to_s)].pack("m0").tr('+/=lIO0', 'pqrsxyz')[0,6]
      [self.class.type, suffix].join("-")
    end

    def generate_pattern
      return config[:pattern] if Regexp === config[:pattern]

      string = Regexp.quote(config[:pattern])
      string.gsub!("\\*", ".*")
      string.gsub!("\\?", ".")
      string.gsub!(/\\\{(.+?)\\\}/) do |match|
        "(?:#{$1.split(",").join("|")})"
      end
      Regexp.new "^#{string}$"
    end

end
