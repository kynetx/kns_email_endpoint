require 'lib/kns_email_endpoint'

$CONFIG_FILE = File.join(File.dirname(__FILE__), '../..', 'test_config_file.yml') 

module KNSEmailEndpoint
  describe Configuration do

    Configuration.load_from_file $CONFIG_FILE
    let(:c) { Configuration }

    it "should have a storage engine" do
      c.storage_engine.should_not be_nil
    end

    describe "loaded" do

      specify { c.work_threads.should eql 5}
      specify { c.poll_delay.should eql 30}
      specify { c.logdir.should eql "/tmp/email_endpoint"}
      specify { c.connections.should_not be_empty }
      specify { c.storage.should_not be_empty }
      specify { c.log.class.should == Logger }
      specify { c.storage_engine.class.should == KNSEmailEndpoint::Storage::MemcacheStorage }
      specify { c.log.level.should == 0 }

    end


    describe "access connections" do

      it 'should return a connection by name' do
        c["test"]["name"].should eql "test"
      end

      it "should let me loop through the connections" do
        c.each_connection do |conn|
          ["test", "gmail"].should include(conn.name)
        end

      end
    end

  end
end
