module FluQ::URL

  # @param [String] url the URL
  # @params [Array] schemes allowed schemes
  # @raises URI::InvalidURIError if URL or scheme is invalid
  def self.parse(url, schemes = ["tcp", "unix"])
    url = URI.parse(url)
    case url.scheme
    when *schemes
      url
    else
      raise URI::InvalidURIError, "Invalid URI scheme, only #{schemes.join(', ')} are allowed"
    end
  end

end