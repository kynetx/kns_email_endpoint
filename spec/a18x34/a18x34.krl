ruleset a18x34 {
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
