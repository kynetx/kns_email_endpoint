require 'lib/kns_email_endpoint'
require 'ap'
#$KNS_ENDPOINT_DEBUG = true
describe KNSEmailEndpoint::EmailEndpoint do


  before :all do
    @mail = KNSEmailEndpoint::EmailEndpoint.new({
      :ruleset => :a18x34,
      :environment => :development,
      :use_session => true,
      :logging => true
    })

    @test_message_file = File.join(File.dirname(__FILE__), '../..', 'test_email.eml')
    @test_message = File.open(@test_message_file, "r").read;
  end


  describe "Events" do 
    it "should send an mail received event" do
      lambda {@mail.received(:msg => @test_message, :label => "parts")}.
        should_not raise_error
      @mail.status.should eql :processing
    end

    it "should receive a delete directive" do
      @mail.received(:msg => @test_message, :label => "delete_me");
      @mail.status.should eql :deleted
    end


  end

  describe "Directives" do 
    # Stub out the actual Connection methods so we don't have to actually 
    # do anything. Just test to make sure the directives are called.


    it "should delete a message"

    it "should forward a message"

    it "should reply to a message"
  end

  

end
