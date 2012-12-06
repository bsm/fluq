require 'digest/md5'

class Fluq::Handler::Base

  # @attr_reader [String] name unique name
  attr_reader :name

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options
  # @option options [String] name a (unique) handler identifier
  # @option options [String] pattern tag pattern to match
  # @example
  #
  #   class MyHandler < Fluq::Handler::Base
  #   end
  #   MyHandler.new(pattern: "visits.*")
  #
  def initialize(options = {})
    @config = defaults.merge(options)
    @name   = config[:name] || Digest::MD5.hexdigest([self.class.name, config[:pattern]].join)
  end

  # @return [Boolean] true if tag matches
  def match?(tag)
    File.fnmatch? config[:pattern], tag.to_s
  end

  # @abstract callback, called on each event
  # @param [Fluq::Event] the event
  def on_event(tag, timestamp, record)
  end

  protected

    # Configuration defaults
    def defaults
      { pattern: "*" }
    end

end