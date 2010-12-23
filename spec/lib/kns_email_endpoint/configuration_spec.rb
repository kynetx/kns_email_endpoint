require 'rubygems'
require 'lib/kns_email_endpoint'
require 'ap'

describe KNSEmailEndpoint::Configuration do

  before :all do 
    @test_config_file = File.join(File.dirname(__FILE__), '../..', 'test_config_file.yml') 
    ap @test_config_file
  end
  
  it 'has a valid test yaml config file' do
    File.exists?(@test_config_file).should == true
  end

  describe "Initialized Configuration" do
    before :all do
      @conf = KNSEmailEndpoint::Configuration.new(@test_config_file)
    end

    it 'should initialize a valid configuration' do
      @conf.storage_mode.should == "stateless"
      @conf.worker_threads.should == 40
      @conf.poll_delay_seconds.should == 30
      @conf.connections.class.should == Array
      @conf.connections.empty?.should_not == true
    end

    it 'should have a valid log' do
      @conf.log.class.should == Logger
    end
    
    it 'should create a master log file' do
      File.exists?("/tmp/email_endpoint/email_endpoint.log").should == true
    end

  end
  
end
