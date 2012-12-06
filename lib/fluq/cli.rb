require "optparse"
require "fluq/version"

module FluQ
  class CLI

    attr_reader :options

    def self.run
      new.run
    end

    def initialize
      @options = {}
      parser.parse!(ARGV)
    end

    def run
      unless options[:config] && File.file?(options[:config])
        puts parser
        exit
      end

      ENV["FLUQ_ENV"] = options[:env] if options[:env]

      require 'fluq'
      STDOUT.puts "Starting Fluq #{FluQ::VERSION}"
      FluQ::DSL.new(options[:config]).run

      if options[:daemon]
        exit!(0) if fork
        Process.setsid
        exit!(0) if fork
        Dir::chdir("/")
        File::umask(0)
        STDIN.reopen("/dev/null")
        STDOUT.reopen("/dev/null", "w")
        STDERR.reopen("/dev/null", "w")
      end

      if options[:log]
        Fluq.log_to(options[:log])
      end

      if options[:verbose]
        Fluq.logger.level = ::Logger::DEBUG
      end

      @pidfile = options[:pidfile] || FluQ.root.join("tmp", "pids", "#{FluQ.env}.pid")
      FileUtils.mkdir_p(File.dirname(@pidfile))
      File.open(@pidfile, "w") {|f| f.write Process.pid }

      Signal.trap("INT", &method(:quit))
      Signal.trap("TERM", &method(:quit))
      Signal.trap("QUIT", &method(:quit))

      sleep
    end

    def quit(*)
      STDOUT.puts "Shutting down ..."
      FileUtils.rm_f(@pidfile) if @pidfile
      exit
    end

    protected

      def parser
        @parser ||= OptionParser.new do |o|
          o.banner = "Usage: #{File.basename($0)} [OPTIONS]"

          o.separator ""
          o.separator "Required:"

          o.on "-C", "--config FILE", "Use this config file" do |val|
            @options[:config] = val
          end

          o.separator ""
          o.separator "Optional:"

          o.on("-e", "--environment ENV", "The environment, defaults to 'development'") do |val|
            @options[:env] = val
          end

          o.on("-l", "--log FILE", "File to log to") do |val|
            @options[:env] = val
          end

          o.on("-v", "--verbose", "Use verbose output") do |val|
            @options[:verbose] = true
          end

          o.separator ""

          o.on "-d", "--daemonize", "Run as a daemon" do
            @options[:daemon] = true
          end

          o.on "--pidfile FILE", "Path to pidfile, defaults to tmp/pids/ENVIRONMENT.pid" do |val|
            @options[:pidfile] = val
          end

          o.separator ""

          o.on("-h", "--help", "Show this message") do
            puts o
            exit
          end

          o.on("-V", "--version", "Show version") do
            puts FluQ::VERSION
            exit
          end
        end
      end

  end
end
