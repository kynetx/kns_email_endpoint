# KNS Email Endpoint
The KNS Email Endpoint is available as a ruby gem that allows a simple application to be built which acts as an email endpoint.

## KNS Events Supported
  - received

## KNS Directives Supported
  - delete
    Deletes the email message passed in the received event
  - reply 
    Replies to the email message passed in the received event. Takes an optional parameter to delete the message after delete.
  - forward
    Forwards the email message to a specified email address. Takes an optional parameter to delete the message after delete.
  - processed
    Marks the email as processed so that it isn't processed in the future.


## Example KRL

    ruleset [REDACTED] {
      meta {
        name "Test App for Email Endpoint"
        description <<
          Testing application for the Email Endpoint
        >>
        author "Michael Farmer"
        // Uncomment this line to require Marketplace purchase to use this app.
        // authz require user
        logging on
      }


      global {
      
      }

      rule receive_new_email is active {
        select when mail received test_rule "parts"
        pre { 
          envelope = event:param("msg");
          from = event:param("from");
          to = event:param("to");
          subject = event:param("subject");
          label = event:param("label");
          unique_id = event:param("unique_id");
          collection = {
            "from": from,
            "to": to,
            "subject": subject,
            "label": label,
            "unique_id": unique_id
          }
        }
        {
          send_directive("processed");
        } 

        fired {
          log collection.encode();
        }

      }

      rule delete_mail is active {
        select when mail received test_rule "delete_me"
        {
          email:delete();
        }
          
      }

      rule reply_mail is active {
        select when mail received test_rule "reply"

        {
          email:reply() with body = "This is a reply message";
        }
      }

      rule reply_and_delete_mail is active {
        select when mail received test_rule "reply and delete"

        {
          email:reply() with body = "This is a reply message" and delete_message = true;
        }
      }


      rule forward_mail is active {
        select when mail received test_rule "forward"
        pre {
          fwd_to = event:param("forward_to");
        }
        {
          email:forward() with to = fwd_to and body = "This is a forwarded message"
        }
          
      }

      rule forward_and_delete_mail is active {
        select when mail received test_rule "forward and delete"
        pre {
          fwd_to = event:param("forward_to");
        }
        {
          email:forward() with to = fwd_to and body = "This is a forwarded message" and delete_message = true;
        }
          
      }
    }
      


