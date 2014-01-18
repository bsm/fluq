# Main feed
feed "main" do

  # Listen on a UDP socket
  input :socket do
    bind    "udp://127.0.0.1:6789"
    format  :json
  end

  # Log all events to a path
  handler :log do
    path "/var/log/main/%Y%m%d/%H.log"
  end

end

# Priority feed
feed "priority" do

  # Listen on a TCP socket
  input :socket do
    bind    "tcp://127.0.0.1:6789"
    format  :json
  end

  # Pull Kafka topic (requires fluq-kafka Gem)
  input :kafka do
    topic      "orders"
    brokers    ["host1:9092", "host2:9092"]
    zookeepers ["host1:2181", "host2:2181"]
    format     :msgpack
  end

  # Pull another Kafka topic
  input :kafka do
    topic      "deliveries"
    brokers    ["host1:9092", "host2:9092"]
    zookeepers ["host1:2181", "host2:2181"]
    format     :msgpack
  end

  # Log all events to a path
  handler :log do
    path "/var/log/priority/%Y%m%d/%H.log"
  end

  # Use your own custom handler to e.g. send notification emails
  handler :email do
    to "relevant.party@example.com"
  end

end
