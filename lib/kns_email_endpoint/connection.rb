require 'net/smtp'
require 'mail'

module KNSEmailEndpoint
  class ConnectionException < StandardError  
  end  


  module ConnectionFactory
    attr_reader :conn_log, :retriever, :sender, :name, :process_mode, :event_args, :appid, :environment, :max_retry_count

    def setup_mail_connections(name)
      @config = Configuration
      @conn_config = @config[name]
      @conn_log = Logger.new("#{@config.logdir}/#{@conn_config['logfile']}", "daily")
      @name = @conn_config["name"]
      @process_mode = @conn_config["processmode"].to_sym
      @max_retry_count = @conn_config["max_retry_count"] || 10
      @event_args = @conn_config["args"] || {}
      @appid = @conn_config["appid"]
      if @conn_config["appversion"] && 
        (@conn_config["appversion"] == "dev" || @conn_config["appversion"] == "development")
        @environment = :development
      else
        @environment = :production
      end


      @in_method = @conn_config["incoming"]["method"]
      @out_method = @conn_config["smtp"]["method"]

      @retriever_settings = {
        :address => @conn_config["incoming"]["host"],
        :user_name => @conn_config["incoming"]["username"],
        :password => @conn_config["incoming"]["password"],
        :enable_ssl => @conn_config["incoming"]["ssl"],
        :port => @conn_config["incoming"]["port"]
      }

      @mailbox = @conn_config["incoming"]["mailbox"]
      @retriever = lookup_retriever

      @sender_settings = {
        :address => @conn_config["smtp"]["host"],
        :user_name => @conn_config["smtp"]["username"],
        :password => @conn_config["smtp"]["password"],
        :port => @conn_config["smtp"]["port"],
        :domain => @conn_config["smtp"]["helo_domain"],
        :enable_starttls_auto => @conn_config["smtp"]["tls"]
      }
      if @conn_config["smtp"]["authentication"]
        @sender_settings[:authentication] = @conn_config["smtp"]["authentication"].downcase
      end
      
      @sender = lookup_sender
    end


    private

    def lookup_retriever
      case @in_method 
        when "imap" then return Mail::IMAP.new(@retriever_settings)
        when "pop3" then return Mail::POP3.new(@retriever_settings)
        when "test" then return Mail::TestRetriever.new(@retriever_settings)
        else return Mail::IMAP.new(@retriever_settings)
      end   
    end

    def lookup_sender
      case @out_method
      when "smtp" then return Mail::SMTP.new(@sender_settings)
      when "test" then return Mail::TestMailer.new(@sender_settings)
      else return Mail::SMTP.new(@sender_settings) 
      end
    end

  end

  class Connection
    include ConnectionFactory
    def initialize(name)
      setup_mail_connections name
      conn_log.info "Setup Connection for '#{name}'"
    end
  end
end

