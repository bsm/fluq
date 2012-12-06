
input :socket do
  bind "tcp://0.0.0.0:23450"
end

input :socket do
  bind "unix:///tmp/fluq.sock"
end

handler :forward do
  pattern "visits.*"
  to      ["tcp://aggregator-01.remote:23450", "tcp://aggregator-02.remote:23450"]
  buffer  "file"
  flush_interval 30.seconds
end

handler :forward do
  pattern "other.*"
  to      ["tcp://aggregator-02.remote:23450"]
  buffer  "file"
  flush_interval 5.minutes
end

handler :counter do
  pattern  "*"
  path     "log/counts"
  format   "%Y%m%d%H"
end