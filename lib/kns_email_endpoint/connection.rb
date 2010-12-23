require 'net/smtp'
require 'mail'
require 'tlsmail'

module KnsEmailEndpoint
  class ConnectionException < StandardError  
  end  

  class Connection
    def initialize(config)
      @config = config

      @log = Logger.new("#{@config['logdir']}/#{@config['logfile']}", "daily")
      log.info "Connection Info Complete"
      @currentlyactivemessages = Set.new
      @currentlock = Mutex.new
    end

    def name
      return @config['name']
    end

    def connect(processingpool)
      begin
        @imap = Net::IMAP.new(@config['imap']['host'])
        @imap.login(@config['imap']['username'], @config['imap']['password'])
        @imap.select(@config['imap']['mailbox'])
      rescue Errno::ECONNREFUSED => e
        log.error "Connection Failure. Retrying in 5 seconds." + e.message
        sleep 5 #seconds
        log.error "Connection Retry Now."
        retry
      end
      #setup idle handling
      #    @imap.add_response_handler do |resp|
      #      # modify this to do something more interesting.
      #      # called every time a response arrives from the server.
      #    
      #      if resp.kind_of?(Net::IMAP::ContinuationRequest)
      #        puts "Continuation Request"
      #      end
      #      if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == "EXISTS"
      #        puts "Mailbox now has #{resp.data} messages"
      #        puts processingpool
      #      end
      #    end
      #@imap.idle
      log.info "connected"
    end

    def message_uids(nextuid)

      log.info "Getting new messages, starting with: #{nextuid}"
      begin
        fulllist = @imap.uid_search(["ALL"])
      rescue Errno::EPIPE => e
        log.error "Pipe Disconnected. Connection Retrying" + e.message
        connect(nil)
        retry
      end
      log.info fulllist
      list = []#@imap.uid_search(["#{nextuid}:#{nextuid.to_i+10000}"])
      if @config['processmode'] == "repeat"
        #process mode - emails will be reprocessed until deleted
        for uid in fulllist
          list << uid
        end
      else
        #single mode
        for uid in fulllist
          if uid.to_i >= nextuid.to_i
            list << uid
          end
        end

      end
      log.info list
      unprocessed = []
      @currentlock.synchronize do
        #remove messages from list that are currently active
        for uid in list
          if @currentlyactivemessages.include?(uid)
            log.info "Currently active: #{uid}"
          else
            unprocessed << uid 
          end
        end

        #add messages to active list
        @currentlyactivemessages.merge(unprocessed)
      end
      return unprocessed
    end

    def message_done(message_uid)
      @currentlock.synchronize do
        @currentlyactivemessages.delete(message_uid)
      end
    end
    
    def appid
      @config['appid']
    end

    def appversion
      if @config['appversion']
        return @config['appversion']
      end
      return "prod"
    end
    
    def specialgeneral
      return true if @config['specialgeneral']
      return false
    end

    def args
      return @config['args'] if @config['args']
      return {}
    end
    
    def fetch_message_body(message_uid)
      log.info "R #{message_uid}"
      begin
        fetchresult = @imap.uid_fetch(message_uid, "RFC822")[0]
        messagebody = fetchresult.attr['RFC822']
        #log.debug messagebody
        log.info "R #{message_uid} done"
      rescue
        log.info "R #{message_uid} fail. No Message Body"
        raise ConnectionException.new("IMAP message retrieval error: No Message Body")
      end
      return messagebody
    end

    def disconnect
      #@imap.done
      @imap.logout
      @imap.disconnect
      log.info "disconnected"
      log.close
    end

    def delete_message(message_uid)
      @imap.uid_store(message_uid, '+FLAGS', [:Deleted])
      @imap.expunge()
      log.info "Message Deleted"
    end

    def reply_to_message(message_uid, messagebody, opts)
      #load original message
      originalmessage = Mail.new(messagebody.to_s)

      #construct reply
      replymessage = Mail.new
      replymessage.to = originalmessage.from
      replymessage.from = @config['smtp']['from']
      replymessage.subject = "RE: #{originalmessage.subject}"
      replymessage.in_reply_to = originalmessage.message_id
      if opts.fetch('attachoriginal', true) == true
        replymessage.add_file({:filename => 'originalmessage.eml', :mime_type => 'message/rfc822', :content => messagebody})
      end

      if opts['message'] and opts['htmlmessage']
        replymessage.text_part = Mail::Part.new do
          body opts['message']
        end
        replymessage.html_part = Mail::Part.new do
          content_type "text/html; charset=UTF-8"
          body opts['htmlmessage']
        end
      elsif opts['htmlmessage']
        replymessage.html_part = Mail::Part.new do
          content_type "text/html; charset=UTF-8"
          body opts['htmlmessage']
        end
        #replymessage.body = opts['htmlmessage']
        #replymessage.content_type = "text/html; charset=UTF-8"
      else #opts['message']
        replymessage.content_type "text/plain; charset=UTF-8"
        replymessage.body = opts['message']
      end  




      #send message
      smtp = Net::SMTP.new(@config['smtp']['host'], @config['smtp']['port'])
      #smtp.set_debug_output $stdout
      smtp.enable_tls OpenSSL::SSL::VERIFY_NONE
      smtp.start(@config['smtp']['helo_domain'], @config['smtp']['username'], @config['smtp']['password'], :login) do |smtp|
        smtp.send_message replymessage.encoded, @config['smtp']['from'], originalmessage.from
      end
      log.info "Reply Sent"
    end

    def forward_messsage(message_uid, messagebody, opts)
      #load original message
      originalmessage = Mail.new(messagebody.to_s)

      #construct reply
      replymessage = Mail.new
      replymessage.subject = "Forward: #{originalmessage.subject}"
      replymessage.in_reply_to = originalmessage.message_id

      if opts['message'] and opts['htmlmessage']
        replymessage.text_part = Mail::Part.new do
          body opts['message']
        end
        replymessage.html_part = Mail::Part.new do
          content_type "text/html; charset=UTF-8"
          body opts['htmlmessage']
        end
      elsif opts['htmlmessage']
        replymessage.content_type = "text/html; charset=UTF-8"
        replymessage.body = opts['htmlmessage']
      else #opts['message']
        replymessage.body = opts['message']
      end  

      replymessage.add_file({:filename => 'originalmessage.eml', :mime_type => 'message/rfc822', :content => messagebody})

      #send message
      smtp = Net::SMTP.new(@config['smtp']['host'], @config['smtp']['port'])
      smtp.enable_tls OpenSSL::SSL::VERIFY_NONE
      smtp.start(@config['smtp']['helo_domain'], @config['smtp']['username'], @config['smtp']['password'], :login) do |smtp|
        smtp.send_message replymessage.encoded, @config['smtp']['from'], opts['to']
      end
      log.info "Forward Sent"
    end

    def log
      @log
    end
    
  end

end


class Net::IMAP
   def idle
     cmd = "IDLE"
     synchronize do
       tag = generate_tag
       put_string(tag + " " + cmd)
       put_string(CRLF)
     end
   end
   def done
     cmd = "DONE"
     synchronize do
       put_string(cmd)
       put_string(CRLF)
     end
   end
end
