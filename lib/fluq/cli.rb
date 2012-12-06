require 'fluq'
require 'optparse'
require 'English'

class Fluq::CLI

  def self.run
    new
    require 'irb'
    require 'irb/completion'
    IRB.start
  end

  def initialize
    parser.parse!
  end

  protected

    def parser
      @parser ||= OptionParser.new do |o|
        o.banner = "Usage: #{File.basename($PROGRAM_NAME)}"
        o.on('-e FLUQ_ENV', String, 'Environment') {|env| ENV['FLUQ_ENV'] = env }
        o.on('-C CONFIG_PATH', 'Config path') {|v|  }
        o.on('-h', 'Help') { puts o; exit }
      end
    end

end
