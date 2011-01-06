require 'lib/kns_email_endpoint'
require 'ap'
#$KNS_ENDPOINT_DEBUG = true

module KNSEmailEndpoint
  test_config_file = File.join(File.dirname(__FILE__), '../..', 'test_config_file.yml') 
  Configuration.load_from_file(test_config_file)
  

  describe EmailEndpoint do
    include ConnectionFactory


    before :all do
      setup_mail_connections "test"

      @mail = EmailEndpoint.new("test", {
        :ruleset => :a18x34,
        :environment => :development,
        :use_session => true,
        :logging => true
      }, sender)

      MessageState.set_storage :memcache, {}

      @test_message_file = File.join(File.dirname(__FILE__), '../..', 'test_email.eml')
      @test_message = Mail.new(File.open(@test_message_file, "r").read);
    end


    describe "Events" do 
      it "should send an mail received event" do
        lambda {@mail.received(:msg => @test_message, :test_rule => "parts", :extract_label => true)}.
          should_not raise_error
        @mail.status.should eql :processed
      end

      it "should receive a delete directive" do
        @mail.received(:msg => @test_message, :test_rule => "delete_me")
        @mail.status.should eql :deleted
      end

      describe "reply" do
        before :all do 
          Mail::TestMailer.deliveries = []
          @mail.received(:msg => @test_message, :test_rule => "reply")
        end

        subject { @mail.status }
        it { should eql :replied }

        it "should be included in deliveries" do
          reply = Mail::TestMailer.deliveries.first
          reply.to.first.should eql "mjf@kynetx.com"
        end
        
      end

      describe "reply and delete" do
        before :all do
          @mail.received(:msg => @test_message, :test_rule => "reply and delete")
        end

        subject { @mail.status }
        it { should eql :deleted }
      end

      describe "forward" do
        before :all do
          Mail::TestMailer.deliveries = []
          @mail.received(:msg => @test_message, :test_rule => "forward", :forward_to => "test@example.com")
        end

        subject { @mail }
        its (:status) { should eql :forwarded }

        it "should be included in deliveries" do
          forward = Mail::TestMailer.deliveries.first
          forward.to.first.should eql "test@example.com"
        end
      end

      describe "forward and delete" do
        before :all do
          @mail.received(:msg => @test_message, :test_rule => "forward and delete", :forward_to => "test@example.com")
        end

        subject { @mail.status }
        it { should eql :deleted }
      end

    end



  end
end
