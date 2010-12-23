require 'mail'

module KNSEmailEndpoint

  class EmailEndpoint < Kynetx::Endpoint
    attr_reader :status

    domain :mail
    event :received do |p|
      raise "Missing 'msg' parameter'." unless p[:msg]
      message = Mail.new(p[:msg])
      p[:to] = message.to.join(",")
      p[:from] = message.from.join(",")
      p[:subject] = message.subject
    end

    def before_received
      @status = :processing
    end

    directive :delete do |d|
    end

    def after_delete(d)
      @status = :deleted
    end

    def initialize(opts={})

      @status = :init
      super(opts)
      
    end


    


  end
end
