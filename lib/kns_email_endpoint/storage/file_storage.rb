require 'json'
require 'fileutils'
module KNSEmailEndpoint
  module Storage
    class FileStorage < AbstractStorage
      attr_reader :name

      def initialize(settings={})
        @dir = settings[:file_location]
        raise "Unknown file_location" unless @dir
        FileUtils.mkdir_p @dir

        super(settings)
        @name = "file"
                
      end

      def delete
        return false unless @current_file
        FileUtils.rm @current_file if File.exists? @current_file
        reset_storage
        return true
      end

      def create(opts={})
        options = {
          :state => :unprocessed,
          :retry_count => 0
        }.merge! opts
        raise ":unique_id is required" unless options[:unique_id]
        raise ":message_id is required" unless options[:message_id]

        @current_file = File.join(@dir, options[:unique_id]) 

        if File.exists? @current_file
          raise "unique_id #{options[:unique_id]} already exists"
        end
        
        set_vars(options)
        save!
        
        return true
      end

      def find(unique_id)
        lookup_file = File.join(@dir, unique_id)
        if File.exists? lookup_file
          @current_file = lookup_file
          set_vars JSON.parse(File.open(@current_file, 'r').read)
          return self
        else
          reset_storage
          return nil
        end
      end

      def delete_all
        FileUtils.remove_dir(@dir, true)
        FileUtils.mkdir_p @dir
      end


      private

      def save!
        File.open(@current_file, "w") do |f|
          f.write to_h.to_json
        end
      end


    end
  end
end
