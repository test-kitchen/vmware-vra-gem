require 'net/http'

module Vra
  module Http
    def self.execute(params)
      request = Request.new(params)
      response = request.call
      response = response.forward(request).call until response.final?
      fail error(response) unless response.success?
      response
    end

    def self.error(response)
      Error.from_response(response)
    end

    class Request
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def redirectable?
        [:get, :head].include?(params[:method])
      end

      def redirect_to(location)
        new(url: location)
      end

      def see_other(location)
        redirect_to(location).new(method: :get)
      end

      def call
        uri = URI(params[:url]) || fail(':url required')

        ssl_params = { use_ssl: uri.scheme == 'https' }
        ssl_params[:verify_mode] = OpenSSL::SSL::VERIFY_NONE unless verify_ssl?

        Net::HTTP.start(uri.host, uri.port, ssl_params) do |http|
          request = http_request(params[:method], uri)
          request.initialize_http_header(params[:headers] || {})
          request.body = params[:payload] || ''

          Response.new(http.request(request))
        end
      end

      def http_request(method, uri)
        type = {
          get: Net::HTTP::Get,
          head: Net::HTTP::Head,
          post: Net::HTTP::Post
        }.fetch(method, nil)

        fail "Unknown HTTP method #{method}!" unless type

        type.new(uri)
      end

      protected

      def new(new_params)
        self.class.new(params.dup.merge(new_params))
      end

      def verify_ssl?
        return true if params[:verify_ssl].nil?
        params[:verify_ssl]
      end
    end

    class Response
      # For hiding the details of the HTTP response class
      # so it can be swapped out easily
      def initialize(response)
        @response = response
      end

      def forward(request)
        if redirect?
          fail Http.error(self) unless request.redirectable?
          request.redirect_to(location)
        elsif see_other?
          request.see_other(location)
        else
          request
        end
      end

      def location
        @response['location']
      end

      def body
        @response.body
      end

      def code
        @response.code.to_i
      end

      def message
        @response.message
      end

      def success_ok?
        code == 200
      end

      def success_no_content?
        code == 204
      end

      def success?
        (200..207).cover?(code)
      end

      def redirect?
        [301, 302, 307].include?(code)
      end

      def see_other?
        code == 303
      end

      def final?
        !(redirect? || see_other?)
      end
    end

    class Error < StandardError
      def self.from_response(http_response)
        new(http_response.message, http_response.code, http_response.body)
      end

      attr_reader :http_code
      attr_reader :response

      def initialize(message, http_code, response)
        super(message)
        @http_code = http_code
        @response = response
      end
    end
  end
end
