require 'kns_email_endpoint/storage/abstract_storage'
module KNSEmailEndpoint
  module Storage
    autoload :FileStorage, 'kns_email_endpoint/storage/file_storage'
    autoload :MemcacheStorage, 'kns_email_endpoint/storage/memcache_storage'

    def self.get_storage(engine, settings)
      case engine.to_sym
        when :file then return FileStorage.new(settings)
        when :memcache then return MemcacheStorage.new(settings)
        else return nil
      end
    end
  end
end
