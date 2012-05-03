require 'net/http'
require 'uri'

module HttpSimple
  
  def self.request
    req = Request.new
    if block_given?
      yield req
    end
  end
  
  class Request
    attr_accessor :headers, :max_redirects, 
      :strict_ssl, :timeout
    def initialize      

      @headers = {}
      @max_redirects = 3
      @strict_ssl = true
      @timeout = 90
                  
    end
    
    def get(url, params=nil)
      uri = URI(url)
      uri.query = URI.encode_www_form(params) if params
      request = Net::HTTP::Get.new(get_path(uri))

      if block_given?      
        yield uri, request
      else
        fetch(uri, request, @max_redirects)      
      end
      
    end
    
    def post(url, body=nil)
      uri = URI(url)      
      request = HTTP::Post.new(get_path(uri))
      
      case body
      when String
        request.body = post_body
      when Hash
        request.set_form_data(post_body)
      end
      
      if block_given?      
        yield uri, request
      else
        fetch(uri, request, @max_redirects)      
      end
      
    end
     
    def fetch(uri, request, limit=0)
      raise "Max redirects (#{@max_redirects}) exceeded." if limit < 0
                
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @scrict_ssl
      http.read_timeout = @timeout
      
      @headers.each_pair { |k,v| request[k] = v } unless @headers.empty?
            
      response = http.start do |http|
        http.request(request)
      end
      
      case response
      when Net::HTTPSuccess
        return response
      when Net::HTTPRedirection
        block = lambda { |url, req| fetch(url, req, limit - 1) }
        if request.is_a? Net::HTTP::Get
          get(response['location'], &block) 
        elsif request.is_a? Net::HTTP::Post
          post(response['location'], &block)
        end
      else response.error!
      end
      
    end
    
    def get_path(uri)
      if uri.path.length < 0 and uri.query.nil?
        "/"
      elsif uri.query.nil?
        uri.path
      else
        "#{uri.path}?#{uri.query}"
      end
    end
  end    
end
