input :socket do
  bind 'tcp://localhost:7654'
end

handler :forward do
  to 'tcp://localhost:8765'
end
