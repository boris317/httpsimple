# httpsimple

Thin wrapper around net/http. Handles HTTPS and follows redirects.

## Install
```
$ gem install HttpSimple
```
	
## Examples

```Ruby
require 'httpsimple'
# Get request
response = HttpSimple.get('http://www.service.com/user')
# Adding query parameters
response = HttpSimple.get('http://www.service.com/user', :username => 'bob')

# response is a Net::HTTPOk instance.
puts response.body

# POST request
response = HttpSimple.post('http://www.service.com/user', :username => 'bob')
# You can also pass a string for the post body
response = HttpSimple.post('http://www.service.com/user', 'I am the post body!')

# Stuff you can set
url = 'https://www.service.com/login'
response = HttpSimple.post(url, :username => 'bob', :password => '1234') do |http|
  # headers
  http.headers['Accept'] = 'gzip, deflate' 
  # read time out (default 90)
  http.timeout = 120
  # max number of redirects to follow (default 3)
  http.max_redirects = 2
  # turn off ssl cert verification - dangerous
  http.strict_ssl = false
end
```


