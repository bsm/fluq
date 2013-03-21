class FluQ::Buffer::File < FluQ::Buffer::Base

  # @attr_reader [File] file instance
  attr_reader :file

  # @see FluQ::Buffer::Base#initialize
  def initialize(*)
    super
    @file = new_file
    @size = 0
  end

  # @see FluQ::Buffer::Base#write
  def write(data)
    file.write(data)
  end

  # @see FluQ::Buffer::Base#size
  def size
    file.size
  end

  # @see FluQ::Buffer::Base#close
  def close
    file.close unless file.closed?
    File.unlink(file.path) if File.exists?(file.path)
  end

  # @see FluQ::Buffer::Base#each
  def each
    file.close unless file.closed?
    stream = File.open(file, 'rb', encoding: Encoding::BINARY)
    MessagePack::Unpacker.new(stream).each do |tag, timestamp, record|
      yield FluQ::Event.new(tag, timestamp, record)
    end
  rescue EOFError
  ensure
    stream.close if stream
  end

  protected

    def defaults
      super.merge(path: "tmp/buffers")
    end

    def new_file
      path = nil
      incr = 0
      path = root.join(generate_name(incr+=1)) until path && !path.exist?
      file = path.open("wb", encoding: Encoding::BINARY)
      file.sync = true
      file
    end

    def root
      @root ||= FluQ.root.join(config[:path]).tap do |full_path|
        FileUtils.mkdir_p full_path.to_s
      end
    end

    def generate_name(index)
      "fluq-buffer-#{(Time.now.utc.to_f * 1000).round}.#{index}"
    end

end
