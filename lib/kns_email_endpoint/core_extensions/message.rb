module Mail
  class Message
    def to_h
      {
        :to => to,
        :from => from,
        :subject => subject,
        :body => body.raw_source
      }
      
    end

    def delivered_to
      # Messages can be sent to multiple people AND if it was forwarded will have multiple
      # Delivered-To headers. What this bit of code does is take the
      # intersection of the "to" recipients and the "Delivered-To" recipients to find
      # out who the message was actually delivered to. There will almost never
      # be more than one recipient in that intersection, but if there is, we'll just 
      # return the first.
      delivered_to_headers = []
      self.header_fields.each { |f| delivered_to_headers << f.value if f.name == "Delivered-To"} 
      actual_to = self.to.to_set.intersection delivered_to_headers
      return actual_to.first
    end
  end
end
