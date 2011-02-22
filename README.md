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
      

# Using the KNS Email Endpoint Gem
The Email Endpoint gem requires a configuration hash, usually supplied by either Configatron or a YAML file.  The gem supports POP3 and IMAP for incoming email and SMTP and SendMail for outgoing email.
To use the endpoint, you will need to create a ruby application that provides configuration information to the gem.
Then all that is needed is to call one or more of the following methods:
    
    KNSEmailEndpoint::ProcessEmail.go(conn)

Runs the endpoint on a given connection.

    KNSEmailEndpoint::ProcessEmail.go_async

Runs the endpoint on all connections in the configuration in their own thread asynchronously.

    KNSEmailEndpoint::ProcessEmail.go_all

Runs the endpoint on all connections in the configuration serially.

## Example

    config_file = "/path/to/yaml"
    KNSEmailEndpoint::Configuration.load_from_file(config_file)
    log = KNSEmailEndpoint::Configuration.log
    log.info "Initialized Endpoint."
    config = KNSEmailEndpoint::Configuration

    @log.info "Starting Message Retrieval"
    KNSEmailEndpoint::ProcessEmail.go_all
    
    
# Configuration File
Below is an example configuration YAML file

    logdir: /tmp/load_test
    logginglevel: debug
    storage:    # Uses either memcache or the filesystem for storing message state
        engine: memcache
        host: localhost
        port: 11211
        ttl: nil
    workthreads: 40
    polldelayinseconds: 10
    connections:
        - name: dev
          appid: a99x999
          appversion: dev
          processmode: repeat
          max_retry_count: 3
          args:
             environment: dev
          incoming:
             method: imap
             host: mail.example.com
             username: my_user
             password: my_pass
             mailbox: INBOX
             port: 143
             ssl: false
          smtp:
             method: smtp
             host: mail.example.com
             username: my_user
             password: my_pass
             port: 26
             helo_domain: example.com
             authentication: login
             tls: true
          logfile: dev.log
        - name: gmail # Connection name. Should be set to human readable name
          appid: a99x98 # Appid of Kynetx application called to process email
          appversion: dev #prod or dev - defaults to prod
          processmode: repeat #repeat or single - defaults to single
          max_retry_count: 2
          args: #optional arguments to publish with each mail recieved event
              test_rule: delete_me
          incoming:
              method: imap # imap or pop3
              host: imap.gmail.com #Hostname of the IMAP server (e.g. hostname.domain.tld)
              username: my_email@gmail.com # Username for IMAP server
              password: my_pass # Password for IMAP server user
              mailbox: INBOX # Name of mailbox being watched (e.g. INBOX)
              port: 993
              ssl: true
          smtp:
              method: smtp
              host: smtp.gmail.com # Hostname of SMTP mail server (e.g. hostname.domain.tld)
              username: my_user@gmail.com # Username for SMTP. *Note* only needed if SMTP authentication is turned on at SMTP - Check with email provider 
              password: my_pass # Password for SMTP user
              port: 587 # SMTP port number *Note* usually this is set to port 25, but could be any port depending on email provider - Check with email provider
              helo_domain: example.com # Domain name of sending domain *Note* this domain must match the domain of the sender and should be resolvable via DNS (i.e. don't make it up)
              authentication: plain # can be login, plain, cram_md5, or it can be commented out if server doesn't require auth
              tls: true
          logfile: gmail.log # Name of logfile for this connection

    


