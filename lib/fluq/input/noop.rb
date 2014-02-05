class FluQ::Input::Noop < FluQ::Input::Base

  # Start the server
  def run
    super
    loop { sleep(1e9) }
  end

end
