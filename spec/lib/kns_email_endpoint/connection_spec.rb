require 'lib/kns_email_endpoint'

RSpec.configure do |c|
  #c.filter_run :filter => true
end


module KNSEmailEndpoint
  # Select which connection to test against
  #  - test: Doesn't actually connect to any mail system so it's fast
  #  - gmail: Uses a test gmail account so it's slow
  # All tests should work for either test or gmail.
  $CONN_TO_TEST = "test"
  test_config_file = File.join(File.dirname(__FILE__), '../..', 'test_config_file.yml') 
  Configuration.load_from_file test_config_file
  

  describe ConnectionFactory, :filter => true do

    before :all do 
      
      class TestConnection
        include ConnectionFactory

        def initialize
          begin
            setup_mail_connections $CONN_TO_TEST
          rescue => e
            ap e.message
            ap e.backtrace
          end
        end

      end

      @conn = TestConnection.new

    end

    it "should have a valid name" do
      @conn.name.should eql $CONN_TO_TEST
    end

    it "should have a valid log" do
      @conn.conn_log.class.should eql Logger
    end

    it "should have a retriever method" do
      @conn.retriever.should_not be_nil
      [Mail::TestRetriever, Mail::IMAP, Mail::POP3].
        should include @conn.retriever.class
    end

    it "should have a sender method" do
      @conn.sender.should_not be_nil
      [Mail::TestMailer, Mail::SMTP].
        should include @conn.sender.class
    end

  end

  describe Connection, :filter => true do
    before :all do 
      @conn = Connection.new $CONN_TO_TEST
    end

    it "should have a valid name" do
      @conn.name.should eql $CONN_TO_TEST
    end

    describe "sending messages", :filter => true do
      before :all do 
        @conn.retriever.delete_all
        @message = Mail.new do
          from 'kynetx.endpoint.test@gmail.com'
          to   'kynetx.endpoint.test@gmail.com'
          subject 'testing 123'
          body    'Testing 123'
        end
      end

      it "should send an email" do
        begin
          lambda { @conn.sender.deliver!(@message) }.
            should_not raise_error
        rescue => e
          ap e.message
          ap e.backtrace
        end
      end

      # Copy the sent emails to the retrievers email to simulate
      # emailing one's self. Only needed if using "test"
      after :all do 
        Mail::TestRetriever.emails = Mail::TestMailer.deliveries if @conn.name == "test"
      end

    end

    describe "receiving messages", :filter => false do
      before :all do
        @message = @conn.retriever.find(:count => 1)
      end

      it "should get mail from test" do
        messages = @conn.retriever.find :count => 2
        messages.should_not be_empty
      end


      it "should be a valid message" do
        @message.to.first.should eql 'kynetx.endpoint.test@gmail.com'
      end

      it "should allow me to delete the message" do
        # demonstrates how to use find to delete messages
        begin
          @conn.retriever.find(:count => 1, :delete_after_find => true) do |msg|
            msg.mark_for_delete = true
          end
          messages = @conn.retriever.find
          messages.should be_empty
        rescue => e
          ap e.message
          ap e.backtrace
        end
      end
      
    end


  end
end
