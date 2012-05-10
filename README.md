# httpsimple

Thin wrapper around net/http. Handles HTTPS and follows redirects.

## Install

    $ gem install httpsimple

## Examples

### GET requests are simple
```Ruby
require 'httpsimple'
# With parameters 
response = HttpSimple.get('http://www.service.com/user', :username => 'bob')
# Without
response = HttpSimple.get('http://www.service.com/user')
```
<tt>response</tt> is a Net::HTTPOk object.

### POST requests are simple
```Ruby
# Parameter as a Hash will send an application/x-www-form-urlencoded request
response = HttpSimple.post('http://www.service.com/user', :username => 'bob')
# You can also pass a string for the post body
response = HttpSimple.post('http://www.service.com/user', 'I am the post body!')
```

### Headers are simple
```Ruby
url = 'http://service.com/user_add'
response = HttpSimple.post(url, '<user>bob</user>') do |simple|
	# 'simple' is an instance of HttpSimple::Http
	simple.headers["Content-Type"] = "text/xml"
end
```

### Other stuff you can set
```Ruby
url = 'https://www.service.com/login'
response = HttpSimple.post(url, :username => 'bob', :password => '1234') do |simple|
  # More headers
  simple.headers['Accept'] = 'gzip, deflate' 
  # Read time out (default 90)
  simple.timeout = 120
  # Max number of redirects to follow (default 3)
  simple.max_redirects = 2
  # Turn off ssl cert verification - dangerous
  simple.strict_ssl = false
end
```

## Response handlers

You can register a code block to run when a certain http status code is received. Your code block
should accept three arguments:

1. Net::HTTP object.
2. Net::HTTPRequest object.
3. Net::HTTPResponse object.
	
```Ruby
simple = HttpSimple.new
simple.add_handler(200) do |http, req, res|
	puts res.code # 200
end
simple.add_handler(301, 302) do |http, req, res|
    puts "#{req.path} was redirected to #{res['location']}!"
end
res = simple.get("http://www.example.com")
```

### Remove response handlers
```Ruby
simple.remove_handler(200)
```


