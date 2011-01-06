require 'lib/kns_email_endpoint'


describe KNSEmailEndpoint::Storage do
  it "should get a FileStorage class" do
    KNSEmailEndpoint::Storage.get_storage(:file, {:file_location => "/tmp"}).class.
      should eql KNSEmailEndpoint::Storage::FileStorage
  end

  it "should get a MemcacheStorage class" do
    KNSEmailEndpoint::Storage.get_storage(:memcache, {}).class.
      should eql KNSEmailEndpoint::Storage::MemcacheStorage
  end
end
