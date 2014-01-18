import "nested/feed1.rb"

feed :feed2 do
  input :socket do
    bind 'udp://localhost:7655'
  end
  handler :log
end

