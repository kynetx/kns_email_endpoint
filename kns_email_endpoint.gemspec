# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kns_email_endpoint/version"

Gem::Specification.new do |s|
  s.name        = "kns_email_endpoint"
  s.version     = KnsEmailEndpoint::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michael Farmer"]
  s.email       = ["mjf@kynetx.com"]
  s.homepage    = "http://code.kynetx.com"
  s.summary     = %q{The Kynetx Email Endpoint is a ruby gem that makes setting up an email endpoint very simple.}
  s.description = %q{The Kynetx Email Endpoint is a ruby gem that makes setting up an email endpoint very simple.}

  s.rubyforge_project = "kns_email_endpoint"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "kns_endpoint", ">= 0.1.9"
  s.add_dependency "mail", ">= 2.2.6.1"
  s.add_dependency "dalli", "~> 1.0.0"
  s.add_dependency "work_queue", "~> 1.0.0"

  #activesupport (3.0.0)
	#daemons (1.1.0)
	#fastthread (1.0.7)
	#i18n (0.4.1)
	#json (1.4.6)
	#mail (2.2.6.1)
	#mime-types (1.16)
	#polyglot (0.3.1)
	#sqlite3-ruby (1.3.1)
	#tlsmail (0.0.1)
	#treetop (1.4.8)
	#work_queue (1.0.0)
end
