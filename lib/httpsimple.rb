require 'net/http'
require 'uri'
require 'cgi'

module HttpSimple
  VERSION='1.0.5'
  def self.get(url, data=nil, &block)
    request(url, :get, data, &block)
  end
  
  def self.post(url, data=nil, &block)
    request(url, :post, data, &block)
  end  
  
  def self.new
    Http.new
  end
  
  def self.request(url, get_or_post, data, &block)
    http = Http.new
    block.call(http) unless block.nil?    
    http.send(get_or_post, url, data)
  end
  private_class_method :request
    
  # Raised when max redirects exceeded.
  class HTTPMaxRedirectError < StandardError
    def initialize(max)
      super("Max redirects (#{max}) exceeded.")
    end
  end
  
  class Http
    attr_accessor :headers, :max_redirects, :debug,
      :strict_ssl, :timeout, :handlers, :follow_redirects
    attr_reader :url
    
    def initialize  

      @headers = {}
      @max_redirects = 3
      @follow_redirects = true
      @strict_ssl = true
      @timeout = 90
      # If debug is set to true ``set_debug_output``
      # will be enabled and write to $stderr
      @debug = false
      # Response handlers
      @handlers = {}
      @set_cookie_headers = []
                  
    end
    
    def handle(*status_codes, &handler)
      # Add response handle for http status code. ie 200, 302, 400
      if block_given?
        status_codes.each { |code| @handlers[code.to_s.to_sym] = handler }
      end
    end
    
    def remove_handler(*status_codes)
      # Remove response handler for http status code.
      status_codes.each { |code| @handlers.delete(code.to_s.to_sym) }
    end
    
    def get(url, params=nil)
      uri = URI(url)
      uri.query = URI.encode_www_form(params) unless params.nil?
      request = Net::HTTP::Get.new(uri.request_uri)

      if block_given?      
        yield uri, request
      else
        fetch(uri, request, @max_redirects)      
      end
      
    end
    
    def post(url, body=nil)
      uri = URI(url)      
      request = Net::HTTP::Post.new(uri.request_uri)
      
      case body
      when String
        request.body = body
      when Hash
        request.set_form_data(body)
      end
      
      if block_given?      
        yield uri, request
      else
        fetch(uri, request, @max_redirects)      
      end
      
    end
     
    private 
     
      def fetch(uri, request, limit=1)                
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @scrict_ssl
        http.set_debug_output $stderr if @debug
        http.read_timeout = @timeout
      
        @headers.each_pair { |k,v| request[k] = v } unless @headers.empty?
            
        response = http.start do |http|
          http.request(request)
        end
      
        code = response.code.to_sym
        if @handlers.key?(code)
          @handlers[code].call(http, request, response)
        end
              
        case response
        when Net::HTTPSuccess
          return update_response_cookies(response)
        when Net::HTTPRedirection
          return response unless @follow_redirects
          raise_error_if_redirection_limit_reached(limit)
          new_uri = URI(response['location'])
          # Handle relative redirects ie /foo        
          new_uri = uri + new_uri unless new_uri.is_a? URI::HTTP
          merge_request_cookies(get_cookies_for_redirect(response))
          block = lambda { |url, req| fetch(url, req, limit - 1) }
                
          if request.is_a? Net::HTTP::Get
            get(new_uri, &block) 
          elsif request.is_a? Net::HTTP::Post
            post(new_uri, &block)
          end
        when Net::HTTPResponse
          response.error!
        end
      
      end
    
      def raise_error_if_redirection_limit_reached(limit)
        raise HTTPMaxRedirectError.new(@max_redirects) if limit == 0
      end    
            
      def get_cookies_for_redirect(response)
        cookies = response.get_fields("set-cookie")
        return if cookies.nil?        
        @set_cookie_headers.concat(cookies)
        
        cookies.collect! {|raw_cookie|
          name, value = get_cookie_name_value_pair(raw_cookie)
          "#{name}=#{value}" unless value.nil?
        }.compact!
        
        cookies.join("; ") unless cookies.empty?        
      end
      
      def get_cookie_name_value_pair(raw_cookie)
        ignore = ["domain", "path", "expires"]
        CGI::Cookie::parse(raw_cookie).each_pair { |k,v|
          return k,v[0] unless ignore.include? k.downcase
        }
        raise ArgumentError.new("Invalid set-cookie value: #{raw_cookie}")  
      end 
      
      def merge_request_cookies(cookies)
        # TODO: scrutinize this merging logic. Duplicate cookies from
        # ``cookies`` should probably overwrite the ones in ``@headers``.
        return unless !cookies.nil?
        if @headers.include? "cookie"
          @headers['cookie'] = [@headers['cookie'], cookies].join("; ")
        else
          @headers['cookie'] = cookies
        end
      end
      
      def update_response_cookies(response)
        @set_cookie_headers.each { |cookie|
          response.header.add_field('set-cookie', cookie)
        }
        @set_cookie_headers = []
        response
      end                  
  end    
end
