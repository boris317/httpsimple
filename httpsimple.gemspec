$LOAD_PATH.unshift 'lib'
require 'httpsimple'

Gem::Specification.new do |s|
  s.name         = "HttpSimple"
  s.version      = '0.9'
  s.date         = Time.now.strftime('%Y-%m-%d')
  s.summary      = "Simple wrapper around Ruby's net/http"
  s.homepage     = "https://github.com/boris317/httpsimple"
  s.email        = ""
  s.authors      = [ "Shawn Adams" ]
  s.has_rdoc     = false

  s.files        = %w( Gemfile README.md LICENSE )
  s.files       += Dir.glob("lib/httpsimple.rb")

  s.required_ruby_version = ">= 1.8.7"
  s.description  = <<desc
  Simple wrapper around Ruby's net/http library. It supports 
  redirects and HTTPS.
desc
end