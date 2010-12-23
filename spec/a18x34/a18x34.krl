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
    select when mail received label "parts"
    pre { 
      envelope = event:param("msg");
      from = event:param("from");
      to = event:param("to");
      subject = event:param("subject");
      label = event:param("label");
      collection = {
        "from": from,
        "to": to,
        "subject": subject,
        "label": label
      }
    }
    {
      noop();
    } 

    fired {
      log collection.encode();
    }

  }

  rule delete_mail is active {
    select when mail received label "delete_me"
    {
      email:delete();
    }
      
  }
}
