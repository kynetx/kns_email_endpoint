require 'mail'

module KNSEmailEndpoint

  class EmailEndpoint < Kynetx::Endpoint
    attr_reader :conn, :message_state

    domain :mail
    event :received do |p|
      raise "Missing 'msg' parameter'." unless p[:msg]
      message = p[:msg]
      p[:to] = message.to.join(",")
      p[:from] = message.from.join(",")
      p[:subject] = message.subject

      p[:unique_id] = message.message_id unless p[:unique_id]

      if p[:extract_label]
        label = message.delivered_to.match(/\+(.*)@/)[1]
        p[:label] = label.to_s
      end

    end

    def before_received
      @message_state = MessageState.new(@conn, params[:msg])
      @message_state.state = :processing
    end

    directive :delete 
    def after_delete(d)
      @message_state.delete
    end

    directive :reply
    def after_reply(d)
      msg = params[:msg]
      r_msg = Mail.new(msg)
      r_msg.to = msg.from
      r_msg.from = msg.reply_to.nil? ? msg.to : msg.reply_to
      r_msg.subject = d["subject"] ? d["subject"] : "Re: " + msg.subject.to_s
      r_msg.body d["body"] ? d["body"] + msg[:body].to_s : msg.body.to_s
      @sender.deliver!(r_msg) if @sender
      @message_state.state = :replied

      if d["delete_message"]
        @message_state.delete
      end
    end

    directive :forward
    def after_forward(d)
      if d["to"] && @sender
        msg = params[:msg]
        f_msg = Mail.new do
          to d["to"]
          from msg.to
          subject d["subject"] ? d["subject"] : "Fwd: " + msg.subject.to_s
          body d["body"] ? d["body"] + msg[:body].to_s : msg.body.to_s
        end
        @sender.deliver!(f_msg)
        @message_state.state = :forwarded
      else
        @message_state.state = :error
      end

      if d["delete_message"] && status == :forwarded
        @message_state.delete
      end
    end

    directive :processed
    def after_processed(d)
      @message_state.state = :processed
    end

    def initialize(conn, opts={}, sender=nil)
      @conn = conn
      @sender = sender
      super(opts)
    end

    def status
      @message_state.state
    end

  end
end
