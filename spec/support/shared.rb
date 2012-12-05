shared_examples "a buffer" do

  its(:size) { should be(0) }
  it { should respond_to(:flush) }
  it { should respond_to(:push) }

end
