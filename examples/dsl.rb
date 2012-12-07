
input :socket do
  bind "tcp://0.0.0.0:23450"
end

input :socket do
  bind "unix:///tmp/fluq.sock"
end

handler :forward do
  pattern "visits.*"
  to      ["tcp://aggregator-01.remote:23450", "tcp://aggregator-02.remote:23450"]
  flush_interval 30
  buffer  "file" do
    path "/var/log/fluq/buffers/forward/visits"
  end
end

handler :forward do
  pattern "other.*"
  to      ["tcp://aggregator-02.remote:23450"]
  flush_interval 300
  buffer  "file" do
    path "/var/log/fluq/buffers/forward/other"
  end
end

handler :log do
  pattern "*.*"
  path    "/var/log/fluq/all/%Y%m/%d/%H/%t.log.gz"
  rewrite {|tag| tag.split(".")[0] },
end