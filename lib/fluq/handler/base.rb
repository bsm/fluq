require 'digest/md5'

class FluQ::Handler::Base

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
  def initialize(options = {})
    @config = defaults.merge(options)
    @name   = config[:name] || [Digest::MD5.digest([self.class.name.split, config[:pattern]].join)].pack("m0").tr('+/=lIO0', 'pqrsxyz')[0,8]
  end

  # @return [Boolean] true if tag matches
  def match?(tag)
    File.fnmatch? config[:pattern], tag.to_s
  end

  # @abstract callback, called on each event
  # @param [FluQ::Event] the event
  def on_event(event)
  end

  protected

    # Configuration defaults
    def defaults
      { pattern: "*" }
    end

end
