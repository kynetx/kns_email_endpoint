require 'yaml'
require 'logger'
require 'fileutils'

module KNSEmailEndpoint


  class Configuration
    cattr_writer :logdir, :work_threads, :poll_delay, :connections
    cattr_reader :storage_engine

    class << self

      def load_from_file(yaml_file)
        conf = YAML.load_file(yaml_file)
        @@logdir = conf["logdir"] if conf["logdir"]
        @@work_threads = conf["workthreads"] if conf["workthreads"]
        @@poll_delay = conf["polldelayinseconds"] if conf["polldelayinseconds"]
        @@log_level = conf["logginglevel"] if conf["logginglevel"]
        @@connections = conf["connections"] if conf["connections"]
        self.storage = conf["storage"] || {}
      end

      def to_h
        {
          :logdir => logdir,
          :work_threads => work_threads,
          :poll_delay => poll_delay,
          :storage => storage,
          :connections => connections
        }
      end

      def log
        return @@logger if defined?(@@logger) && ! @logger.nil?
        FileUtils.mkdir_p @@logdir
        log_dest = @@logdir == "" ? STDOUT : File.join(@@logdir, 'email_endpoint.log')
        @@logger = Logger.new(log_dest, "daily")
        @@logger.level = eval("Logger::#{@@log_level.upcase}") rescue Logger::DEBUG
        return @@logger
      end

      def log_level=(l)
        @@log_level = l
        @@log = nil
        return @@log_level
      end

      def storage=(opts)
        @@storage = opts
        engine = opts.delete("engine")
        @@storage_engine = MessageState.set_storage(engine, opts)
        return @@storage
      end

      # defaults
      def work_threads; @@work_threads ||= 10 end
      def poll_delay; @@poll_delay ||= 30 end
      def logdir; @@logdir ||= "" end
      def connections; @@connections ||= [] end
      def storage; @@storage ||= {} end

      # Connection Handling

      def [](name)
        @@connections.each do |conn| 
          return conn if conn["name"] == name
        end
        raise "Invalid connection (#{name})" 
      end

      def each_connection
        @@connections.each do |conn|
          yield self[conn["name"]]
        end
      end


    end
  end

end

