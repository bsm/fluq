class FluQ::Feed::Lines < FluQ::Feed::Base
  include MonitorMixin

  # @see FluQ::Feed::Base#initialize
  def initialize(*)
    super
    @buffer = ""
  end

  protected

    # @see FluQ::Feed::Base#feed
    def feed(data)
      last_chunk = nil
      synchronize do
        @buffer << data
        @buffer.each_line do |line|
          line.chomp!
          next if line.empty?

          last_chunk = yield(line) ? nil : line
        end
        last_chunk ? @buffer = last_chunk : @buffer.clear
      end
    end

end
