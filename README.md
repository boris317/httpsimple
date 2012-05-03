# httpsimple

Thin wrapper around net/http. Handles HTTPS and follows redirects.

## Examples

```Ruby
# Set some headers and make a GET request.

response = HttpSimple.request do |http|
  http.headers["Accept"] = "gzip, deflate"
  # http://www.service.com/user?username=bob
  http.get("http://www.service.com/user", :username => "bob")
end
puts response.body


# POST request
response = HttpSimple.request do |http|
  http.headers["Accept"] = "gzip, deflate"
  http.post("http://www.example.com", :form_var1 => "foo", :form_var2 => "bar")
  #You can also pass a string as the post body
  #http.post("http://www.example.com", 'I am post data!')
end
puts response.body

# HTTPS:
response = HttpSimple.request do |http|
  http.headers["Accept"] = "gzip, deflate"
  # For testing purposes you can turn off cert verification
  # http.strict_ssl = false
  http.post("https://www.example.com")
end
puts response.body