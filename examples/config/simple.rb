# Feed definition: a feed 'wraps' a list of inputs and a list of handler
feed "my-feed" do

  # Listen on a TCP socket for JSON formatted messages
  input :socket do
    bind    "tcp://127.0.0.1:6789"
    format  :json
  end

  # Log all events to a timestamped path
  handler :log do
    path "/var/log/%Y%m%d/%H.log"
  end

end
