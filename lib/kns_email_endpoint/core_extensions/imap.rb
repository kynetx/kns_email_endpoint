# Adding methods to imap for easier access to things we do commonly
require 'mail'

module Mail

  class IMAP

    # add a delete message
    # so that we can delete without calling find again

    def delete_messages(mailbox, messages)
      mailbox = Net::IMAP.encode_utf7(mailbox)
      messages.each do |message_hash|
        imap = message_hash[:connection]
        message_id = message_hash[:message_id]
        message = message_hash[:message]
        imap.uid_store(message_id, "+FLAGS", [Net::IMAP::DELETED]) if message.is_marked_for_delete?
      end
      start do |imap|
        begin
          imap.select(mailbox)
          imap.expunge
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
          raise e
        end
      end
      
    end

        

  end

end
