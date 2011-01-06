require 'digest/sha1'
module KNSEmailEndpoint
  class MessageState
    
    class << self 
      attr_accessor :storage

      def set_storage(storage, opts)
        @storage = Storage.get_storage(storage, opts)
        return @storage
      end

      def gen_unique_id(conn,msg)
        raise "Message must have a valid message_id" unless msg.message_id.to_s != ""
        Digest::SHA1.hexdigest "#{conn}::#{msg.message_id}::K-KEY"
      end
    end


    attr_reader :message, :message_id, :retry_count, :unique_id, :state

    def initialize(conn_name, message)
      # setup the state
      @conn_name = conn_name
      @message = message
      @message_id = get_message_id
      @unique_id = get_unique_id 
      @storage = self.class.storage
      raise "Unknown Storage" unless @storage

      # get from storage
      @storage.find_or_create(:unique_id => @unique_id, :message_id => @message_id)
      @state = @storage.state
      @retry_count = @storage.retry_count

    end

    def state=(s)
      @state = s
      @storage.state = @state
      return @state
    end

    def retry
      @retry_count += 1
      @storage.retry_count = @retry_count
      return @retry_count
    end

    def reset
      @retry_count = 0
      @storage.retry_count = @retry_count
      return @retry_count
    end

    def reset_state
      @storage.delete
      @storage.create(:unique_id => @unique_id, :message_id => @message_id)
      @retry_count = @storage.retry_count
      @state = @storage.state
    end

    def delete
      @storage.delete
      @message.mark_for_delete = true
      @unique_id = nil
      @message_id = nil
      @state = :deleted
      @retry_count = nil
    end


    private 

    def get_message_id
      return @message_id if @message_id
      if @message.has_message_id?
        @message_id = @message.message_id
      else
        raise "The mail message does not have a valid message_id."
      end
      return @message_id
    end

    def get_unique_id
      return @unique_id ||= self.class.gen_unique_id(@conn_name, @message)
    end
  end
end
