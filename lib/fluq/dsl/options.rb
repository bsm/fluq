class Fluq::Dsl::Options < Hash

  def method_missing(name, arg)
    store(name.to_sym, arg)
  end

end
