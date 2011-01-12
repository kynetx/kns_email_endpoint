require 'work_queue'
module KNSEmailEndpoint

  class ProcessEmail
    # if in repeat mode, these states will be processed
    $REPEATABLE_STATES = [:forwarded, :replied, :unprocessed, :error]
    # if in single mode, these states will be processed
    $SINGLE_STATES = [:unprocessed, :error] 

    class << self

      def go(conn)
        raise "Need config" unless Configuration[conn.name]
        log = conn.conn_log
        3.times { log.debug "" }
        log.info "Processing Email from connection: #{conn.name}"
        endpoint_opts = {
          :ruleset => conn.appid,
          :environment => conn.environment,
          :use_session => true,
          :logging => log.debug? 
        }

        begin
          queue = WorkQueue.new(Configuration.work_threads)
          email_processed_count = 0
          email_errors_count = 0
          conn.retriever.find({
            :count => :all,
            :delete_after_find => true,
            :what => :first,
            :order => :asc
          }) do |msg|
            # worker enqueue
            queue.enqueue_b {
              begin
                log.debug "Getting Message State for #{msg.message_id}"
                msg_state = MessageState.new(conn.name, msg)
                log.debug "Processing Message #{msg_state.unique_id}"
                log.debug "STATE: #{msg_state.state}"
                if (conn.process_mode == :single && $SINGLE_STATES.include?(msg_state.state)) ||
                   (conn.process_mode == :repeat && $REPEATABLE_STATES.include?(msg_state.state))

                  ee = EmailEndpoint.new(conn.name, endpoint_opts, conn.sender)
                  event_args = {
                    :msg => msg,
                    :unique_id => msg_state.unique_id
                  }.merge! conn.event_args

                  log.debug "Raising Event\n #{event_args.inspect}"
                  result = ee.received(event_args)
                  if log.debug?
                    log.debug "--- Endpoint Log ---"
                    log.debug ee.log.join("\n")
                    log.debug "--------------------"
                  end
                  if ee.message_state.state == :processing
                    # there was no directive returned or endpoint failed.
                    log.debug "UNEXPECTED DIRECTIVE RECEIVED: \n#{result.inspect}"
                    raise "No directive matched message (#{msg.message_id})"
                    
                  end
                  log.debug "NEW STATE: " + ee.message_state.state.to_s
                  log.debug "Delete message? #{msg.is_marked_for_delete?}"
                else
                  log.debug "Skipping #{msg.message_id} (#{msg_state.state})"
                  log.debug "Delete message? #{msg.is_marked_for_delete?}"
                end
                email_processed_count += 1

              rescue => e
                log.error "Error processing email: #{e.message}"
                log.error e.backtrace.join("\n")
                rc = msg_state.retry
                if rc >= (conn.max_retry_count - 1)
                  msg_state.state = :failed
                else
                  msg_state.state = :error
                end
                log.error e.message
                log.error "RETRY COUNT: #{rc}"
                log.error "NEW STATE: #{msg_state.state}"
                log.error "Delete message? #{msg.is_marked_for_delete?}"
                email_errors_count += 1
              end

            }
            queue.join
          end
          log.info "Number of email successfully processed for connection #{conn.name}: #{email_processed_count}"
          log.info "Number of email unsuccesfully processed for connection #{conn.name}: #{email_errors_count}"
        rescue => e
          log.error "There was an error processing email for #{conn.name}: #{e.message}"
        end
        
        
      end

      def go_async
        threads = []
        begin
          Configuration.each_connection do |conn|
            threads << Thread.new { go conn }
          end
          threads.each { |t| t.join }
        rescue => e
          Configuration.log.error e.message
        end
      end

      def go_all
        begin
          Configuration.each_connection { |conn| go conn }
        rescue => e
          Configuration.log.error e.message
        end
      end

      def flush
        # flush all message states
        Configuration.storage_engine.delete_all
      end
    end

  end
end
