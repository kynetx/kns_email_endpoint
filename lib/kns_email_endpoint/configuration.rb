require 'yaml'
require 'logger'
require 'fileutils'

module KNSEmailEndpoint

  class Configuration
    attr_reader :log, :storage_mode, :worker_threads, :poll_delay_seconds, :connections

    def initialize(config_file)
      conf = YAML.load_file(config_file)
      @storage_mode = conf["storagemode"]
      @worker_threads = conf["workthreads"]
      @poll_delay_seconds = conf["polldelayinseconds"]

      # Setup Logging
      setup_logging(conf["logdir"])

      @connections = conf["connections"]
    end


    private


    def setup_logging(log_dir=nil)
      if log_dir
        FileUtils.mkdir_p log_dir
        @log = Logger.new(File.join(log_dir, 'email_endpoint.log'), 'daily')
      else
        @log = Logger.new(STDOUT)
      end
    end

  end

end



#logdir: /Apps/EmailEndpoint/log/ # Set to log directory
#storagemode: stateless #stateless or persistant. if stateless, sqlite is not used.
#workthreads: 40 # Set to number of work threads based on observed performance of Kynetx application. *Warning* incorrectly setting this value to low/high can significantly impact performance of the application
#polldelayinseconds: 30 # Recommended setting is '30'
#connections:
    #- name: example # Connection name. Should be set to human readable name
      #appid: a123x123 # Appid of Kynetx application called to process email
      #appversion: pro #pro or dev - defaults to pro
      #processmode: repeat #repeat or single - defaults to single
      #specialgeneral: false #puts this connection into general mode - not for general use.
      #args: #optional arguments to publish with each mail recieved event
          #arg1: value1
          #arg2: value2
      #imap:
          #host: imap.example.com #Hostname of the IMAP server (e.g. hostname.domain.tld)
          #username: user # Username for IMAP server
          #password: pass # Password for IMAP server user
          #mailbox: INBOX # Name of mailbox being watched (e.g. INBOX)
      #smtp:
          #host: smtp.example.com # Hostname of SMTP mail server (e.g. hostname.domain.tld)
          #username: user # Username for SMTP. *Note* only needed if SMTP authentication is turned on at SMTP - Check with email provider 
          #password: pass # Password for SMTP user
          #port: 25 # SMTP port number *Note* usually this is set to port 25, but could be any port depending on email provider - Check with email provider
          #from: user@example.com # Username outgoing email should be sent as
          #helo_domain: example.com # Domain name of sending domain *Note* this domain must match the domain of the sender and should be resolvable via DNS (i.e. don't make it up)
      #logfile: user.log # Name of logfile for this connection
