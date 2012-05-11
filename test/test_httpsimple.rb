#require File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "httpsimple"))
require 'test/unit'
require 'fakeweb'
require 'httpsimple'

FakeWeb.register_uri(:any, "http://example.com/redirect", :status=>[302, 'Found'], :location=>"http://example.com")
FakeWeb.register_uri(:any, "http://example.com/redirect2", :status=>[302, 'Found'], :location=>"/FooBar")

FakeWeb.register_uri(:get, "http://example.com", :body=>"Get Hello World!")
FakeWeb.register_uri(:get, "http://example.com?foo=bar", :body=>"Get Hello Foo!")
FakeWeb.register_uri(:get, "http://example.com/FooBar", :body=>"Get Hello FooBar!")
FakeWeb.register_uri(:post, "http://example.com", :body=>"Post Hello World!")
FakeWeb.register_uri(:any, "https://example.com", :body=>"Https Hello World!")

class TestModuleMethods < Test::Unit::TestCase
  def test_get
    url = "http://example.com"
    assert_equal HttpSimple.get(url).body, FakeWeb.response_for(:get, url).body
  end
  
  def test_post
    url = "http://example.com"
    assert_equal HttpSimple.post(url).body, FakeWeb.response_for(:post, url).body
  end
  
  def test_post_with_form_param
    url = "http://example.com"
    assert_equal HttpSimple.post(url, :foo => "bar").body, FakeWeb.response_for(:post, url).body    
    assert FakeWeb.last_request.body.include?("foo=bar"), "Post body does not conatin 'foo=bar'"
  end
  def test_get_with_query_string
    url = "http://example.com"
    assert_equal HttpSimple.get(url, :foo => "bar").body, FakeWeb.response_for(:get, "#{url}?foo=bar").body    
    assert FakeWeb.last_request.path.include?("foo=bar"), "Query string does not conatin 'foo=bar'"
  end
end

class TestHttpObject < Test::Unit::TestCase
  def test_get_redirect    
    assert_equal(
      HttpSimple.get("http://example.com/redirect").body, 
      FakeWeb.response_for(:get, "http://example.com").body
    )
  end
  
  def test_post_redirect
    assert_equal(
      HttpSimple.post("http://example.com/redirect").body, 
      FakeWeb.response_for(:post, "http://example.com").body
    )
  end
  def test_relative_uri_redirect
    assert_equal(
      HttpSimple.get("http://example.com/redirect2").body, 
      FakeWeb.response_for(:get, "http://example.com/FooBar").body
    )    
  end
  def test_max_redirects
    url = "http://example.com/recurse"
    FakeWeb.register_uri(:get, url, :status=>[302, 'Found'], :location=>url)
    assert_raises HttpSimple::HTTPMaxRedirectError do
      HttpSimple.get(url)
    end
  end
  def test_dont_follow_redirects
    res = HttpSimple.get("http://example.com/redirect") do |simple|
      simple.follow_redirects = false
    end
    assert_equal res.code, "302"
    assert_equal res['location'], "http://example.com"
  end
  def test_response_handlers    
    http = HttpSimple.new
    handler_ran = false
        
    http.add_handler(301, 302) do |http, req, res|
      assert_equal res.code, "302"
      handler_ran = true
    end
    
    assert_equal http.get("http://example.com/redirect").body, FakeWeb.response_for(:get, "http://example.com").body
    assert handler_ran, "302 response handler did not run!"
  end  
  def test_remove_response_handlers
    
    http = HttpSimple.new
    handler_ran = false
        
    http.add_handler(200) do |http, req, res|
      assert_equal res.code, "200"
      handler_ran = true
    end
    
    http.get("http://example.com")
    assert handler_ran, "200 response handler did not run!"
    
    handler_ran = false
    http.remove_handler(200)
    http.get("http://example.com")
    assert handler_ran==false, "200 response handler should not have run!"    
  end  
  def test_https
    http = HttpSimple.new
    port = nil
    http.add_handler(200) do |http, req, res|
      port = http.port
    end
    http.get("https://example.com")
    assert_equal port, 443
  end
end