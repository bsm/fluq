shared_examples "a buffer" do

  its(:event_count) { should be(0) }
  it { should respond_to(:flush) }
  it { should respond_to(:concat) }

end
