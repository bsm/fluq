class Fluq::Input::Base

  # Constructor.
  # @param [Hash] options
  def initialize(options = {})
    super()
  end

  # @abstract
  def run!
  end

end
