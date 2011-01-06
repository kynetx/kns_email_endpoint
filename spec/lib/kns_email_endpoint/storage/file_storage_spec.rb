require 'lib/kns_email_endpoint'
require 'spec/lib/kns_email_endpoint/storage/shared_storage'


describe KNSEmailEndpoint::Storage::FileStorage do
  storage_dir = "/tmp/kns_email_endpoint/test_file_storage"
  FileUtils.mkdir_p storage_dir
  settings = {
    :file_location => storage_dir
  }
  storage = KNSEmailEndpoint::Storage.get_storage(:file, settings)

  it_should_behave_like "a storage engine", storage


end
