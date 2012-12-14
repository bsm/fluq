require "optparse"
require "fileutils"

module FluQ

  # Partially inspired by https://github.com/nevans/resque-pool
  class CLI
    SIGNALS = [ :QUIT, :INT, :TERM, :HUP ]
    CHUNK_SIZE = (16 * 1024) # 16k

    # attr_reader [Hash] options
    attr_reader :options
    attr_reader :pending_signals, :pipe, :worker

    # Runs the CLI
    def self.run
      if GC.respond_to?(:copy_on_write_friendly=)
        GC.copy_on_write_friendly = true
      end
      new.run
    end

    # Constructor
    def initialize
      super

      # Parse options
      @options = {}
      parser.parse!(ARGV)

      # Setup pipe & signals
      @pipe = IO.pipe
      @pending_signals = []
    end

    def run
      # Exit if not configured correctly
      unless configured?
        puts parser
        exit
      end

      # Set the environment
      if options[:env]
        ENV["FLUQ_ENV"] = options[:env]
      end

      # Boot and add project's lib/ dir to load path
      require 'fluq'
      $LOAD_PATH.unshift FluQ.root.join('lib')
      procline "(starting)"

      # Setup logger
      if options[:log]
        FileUtils.mkdir_p(File.dirname(options[:log]))
        FluQ.logger = ::Logger.new(options[:log])
      end
      if options[:verbose]
        FluQ.logger.level = ::Logger::DEBUG
      end

      # Write PID file
      @pidfile = options[:pidfile] || FluQ.root.join("tmp", "pids", "fluq.pid")
      FileUtils.mkdir_p(File.dirname(@pidfile))
      File.open(@pidfile, "w") {|f| f.write Process.pid }

      # Setup IO pipe
      pipe.each {|io| io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) }

      # Trap signals
      SIGNALS.each {|signal| trap(signal) {|_| on_signal(signal) } }
      trap(:CHLD)   {|_| master_poke! }

      # Spawn worker
      worker_spawn!

      # Start the main loop
      loop do
        break if handle_signals! == :break
        master_sleep! if pending_signals.empty?
      end

      shutdown!
    end

    # @return [Boolean] true if configured
    def configured?
      options[:config] && File.file?(options[:config])
    end

    private

      # Callback, when signal received
      def on_signal(signal)
        if pending_signals.size < 5
          FluQ.logger.debug "Received #{signal}, pending=#{pending_signals.inspect}"
          pending_signals << signal
          master_poke!
        else
          FluQ.logger.debug "Ignoring #{signal}, pending=#{pending_signals.inspect}"
        end
      end

      # Handle all pending signals
      def handle_signals!
        case signal = pending_signals.shift
        when :HUP
          log "Reloading configuration"
          pid = worker_signal!(:QUIT)
          worker_spawn!
          Process.wait(pid)
        when :QUIT, :TERM
          Process.wait worker_signal!(:QUIT)
          :break
        when :INT
          worker_signal!(:QUIT)
          :break
        end
      end

      # Spawn a new worker
      def worker_spawn!
        config = options[:config].dup
        @worker = fork do
          log "Starting FluQ #{FluQ::VERSION}"
          SIGNALS.each {|s| trap(s, "DEFAULT") }
          FluQ::DSL.new(FluQ::Reactor.new, config).run
          procline "(worker)"
          sleep
        end
        procline "(master, managing #{worker})"
      end

      # Send signal to worker
      def worker_signal!(signal)
        pid = worker
        Process.kill signal, pid
        pid
      end

      # Put master asleep
      def master_sleep!
        begin
          ready = IO.select([pipe.first], nil, nil, 1) or return
          ready[0] && ready[0][0] or return
          loop { pipe.first.read_nonblock(CHUNK_SIZE) }
        rescue Errno::EAGAIN, Errno::EINTR
        end
      end

      # Poke master
      def master_poke!
        pipe.last.write_nonblock('.') # wakeup master process from select
      rescue Errno::EAGAIN, Errno::EINTR
        retry # pipe is full, master should wake up anyways
      end

      # Shut down
      def shutdown!
        FluQ.logger.info "Shutting down FluQ" if defined?(FluQ)
        FileUtils.rm_f(@pidfile) if @pidfile
        exit
      end

      def log(message)
        FluQ.logger.info(message)
      end

      def procline(message)
        $0 = "fluq-rb #{FluQ::VERSION} #{message}"
      end

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

          o.on("-e", "--environment ENV", "Runtime environment (default: development)") do |val|
            @options[:env] = val
          end

          o.on("-l", "--log FILE", "File to log to (default: STDOUT)") do |val|
            @options[:log] = val
          end

          o.on("-v", "--verbose", "Use verbose output") do |val|
            @options[:verbose] = true
          end

          o.separator ""

          o.on "--pidfile FILE", "Path to pidfile (default: tmp/pids/fluq.pid)" do |val|
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
