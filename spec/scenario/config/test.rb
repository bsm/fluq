import "nested/common.rb"

handler :forward do
  to 'tcp://localhost:8765'
end
