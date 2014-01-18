feed :feed1 do
  input :socket do
    bind 'tcp://localhost:7654'
  end
  handler :log
end
