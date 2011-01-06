require 'lib/kns_email_endpoint'

$CONN_TO_TEST = "test"
$NUM_TEST_EMAIL = 10 # make sure you tone this down if testing on a connection other than "test"

module KNSEmailEndpoint
  test_config_file = File.join(File.dirname(__FILE__), '../..', 'test_config_file.yml') 
  Configuration.load_from_file(test_config_file)
  
  describe ProcessEmail do 



    before :all do 
      # Setup some email to test against
      @conn = Connection.new($CONN_TO_TEST)
      @conn.retriever.delete_all
      Mail::TestMailer.deliveries = []
      $NUM_TEST_EMAIL.times do |x|
        @conn.sender.deliver!(Mail.new do
          to "kynetx.endpoint.test@gmail.com"
          from "kynetx.endpoint.test@gmail.com"
          subject "Testing #{x}"
          body "Testing body #{x}"
          message_id "TESTEMAIL::#{x}"
        end)
      end

      Mail::TestRetriever.emails = Mail::TestMailer.deliveries if @conn.name == "test"
      
    end

    it "should have 3 email messages ready for testing" do
      @conn.retriever.find.size.should eql $NUM_TEST_EMAIL
    end


    describe "go" do
      before :all do

      end

      it "should go" do
        #lambda { ProcessEmail.go(@conn) }.should_not raise_error
        begin
          ProcessEmail.go(@conn)
        rescue => e
          ap e.message
          ap e.backtrace
        end
        Mail::TestRetriever.emails.should be_empty
      end

    end

    describe "flush" do
      it "should flush" do
        ProcessEmail.flush.should eql true
      end
    end





  end
end
