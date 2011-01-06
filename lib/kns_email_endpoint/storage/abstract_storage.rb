module KNSEmailEndpoint
  module Storage
    class AbstractStorage
      attr_reader :message_id, :unique_id, :retry_count, :state

      def initialize(*args)

        reset_storage
      end

      # delete should return either true if successful, or false if unsuccessful
      # delete should also call reset_storage if successful
      def delete
        return false # override me

      end

      # create should call set_vars and save! if successful and return true
      # otherwise, it should raise an exception
      def create(opts={})
        return false #override me

      end

      # find should return self if a record is found after calling set_vars
      # it should return nil if not found and call reset_storage
      def find(unique_id)
        return nil #override me
      end

      def retry_count=(r)
        raise "Unknown unique_id" unless @unique_id
        @retry_count = r
        save!
      end

      def state=(s)
        raise "Unknown unique_id" unless @unique_id
        @state = s
        save!
      end

      def to_h
        return {} unless @unique_id
        return {
          :unique_id => @unique_id,
          :message_id => @message_id,
          :retry_count => @retry_count,
          :state => @state
        }
      end

      def find_or_create(opts={})
        unless opts[:unique_id] && opts[:message_id]
          raise "Must provide at least a unique_id and message_id"
        end

        s = find(opts[:unique_id])
        return s if s

        return create(opts) ? self : nil
      end

      private

      def save!
        # override me
      end

      def set_vars(h)
        h.symbolize_keys!
        raise "Invalid unique_id" unless h[:unique_id]
        raise "Invalid message_id" unless h[:message_id]
        raise "Invalid retry_count" unless h[:retry_count]
        raise "Invalid state" unless h[:state]
        @unique_id = h[:unique_id]
        @message_id = h[:message_id]
        @retry_count = h[:retry_count]
        @state = h[:state].to_sym
        
      end

      def reset_storage
        @unique_id = nil
        @message_id = nil
        @retry_count = nil
        @state = nil
        @current_file = nil
      end

    end
  end
end
