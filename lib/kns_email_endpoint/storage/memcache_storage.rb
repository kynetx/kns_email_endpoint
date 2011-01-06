require 'dalli'
module KNSEmailEndpoint
  module Storage
    class MemcacheStorage < AbstractStorage
      class << self
        attr_accessor :client
      end

      def initialize(settings)
        options = {
          :host => "localhost",
          :port => 11211,
          :ttl => nil
        }.merge!(settings)


        # This simple bit of magic allows usage of 
        # a class connection rather than an instance connection
        # so we never have more than one active connection to memcache
        self.class.client ||= Dalli::Client.new("#{options[:host]}:#{options[:port]}")
        @client = self.class.client
        @ttl = options[:ttl]
        
      end

      def create(opts={})
        options = {
          :state => :unprocessed,
          :retry_count => 0
        }.merge! opts
        raise ":unique_id is required" unless options[:unique_id]
        raise ":message_id is required" unless options[:message_id]
        
        set_vars(options)
        save!
        
        return true
      end

      def find(unique_id)
        s = @client.get(unique_id)
        if s
          set_vars(s)
          return self 
        else 
          reset_storage
          return nil
        end
      end

      def delete
        return false unless @unique_id
        @client.delete @unique_id
        reset_storage
        return true
      end

      def delete_all
        @client.flush
        reset_storage
        return true
      end
        
      private

      def save!
        @client.set(@unique_id, to_h, @ttl)
      end

    end
  end
end
