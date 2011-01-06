require 'lib/kns_email_endpoint'

module KNSEmailEndpoint
  MessageState.set_storage :memcache, {} 

  describe MessageState do

    before :all do 
      @message = Mail.new do
        to "test@example.com"
        from "joe@example.com"
        subject "This is a test"
        body "This is a test body"
      end
      @message.add_message_id('1234')

      @message_state = MessageState.new("test", @message)
      @message_state.reset_state
    end

    it "should have an initial state of :unprocessed" do
      @message_state.state.should eql :unprocessed
    end

    it "should have a message_id" do
      @message.has_message_id?.should eql true
    end

    it "should have a unique_id" do 
      @message_state.unique_id.should_not be_nil
    end
    
    it "should have a retry count of 0" do
      @message_state.retry_count.should eql 0
    end

    it "should have a message_id" do
      @message_state.message_id.should eql "1234"
    end

    it "should not allow a message without a message_id" do
      lambda { MessageState.new('test', Mail.new) }.
        should raise_error
    end

    it "should allow me to update the state" do
      @message_state.state = :new_state
      @message_state.state.should eql :new_state
    end

    it "should allow me to increment the retry count" do
      rc = @message_state.retry_count
      @message_state.retry
      @message_state.retry_count.should eql rc + 1
    end

    it "should allow me to reset the retry count" do
      @message_state.retry
      @message_state.reset
      @message_state.retry_count.should eql 0
    end

  end
end
