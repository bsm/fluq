class FluQ::Input::Base
  include FluQ::Mixins::Loggable

  # @attr_reader [Hash] config
  attr_reader :config

  # @param [Hash] options varous configuration options
  def initialize(options = {})
    super()
    @config = defaults.merge(options)
  end

  protected

    def defaults
      {}
    end

end
