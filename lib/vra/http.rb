# frozen_string_literal: true

require 'net/http' unless defined?(Net::HTTP)
require 'openssl' unless defined?(OpenSSL)
require 'ffi_yajl' unless defined?(FFI_Yajl)
require 'json'

module Vra
  module Http
    def self.execute(params)
      request = Request.new(params)
      response = request.call
      response = response.forward(request).call until response.final?
      if ENV["VRA_HTTP_TRACE"]
        puts "#{request.params[:method].upcase} #{request.params[:url]}" unless request.params.nil?
        puts ">>>>> #{JSON.parse(request.params[:payload]).to_json.gsub(/\"password\":\"(.+)\",/, '"password":"********",' )}" unless request.params[:payload].nil?
        puts "<<<<< #{JSON.parse(response.body).to_json}" unless response.body.nil?
      end
      raise error(response) unless response.success?

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
        %i{get head}.include?(params[:method])
      end

      def redirect_to(location)
        new(url: location)
      end

      def see_other(location)
        redirect_to(location).new(method: :get)
      end

      def call
        uri = URI(params[:url]) || raise(":url required")

        ssl_params = { use_ssl: uri.scheme == "https" }
        ssl_params[:verify_mode] = OpenSSL::SSL::VERIFY_NONE unless verify_ssl?

        Net::HTTP.start(uri.host, uri.port, ssl_params) do |http|
          request = http_request(params[:method], uri)
          request.initialize_http_header(params[:headers] || {})
          request.body = params[:payload] || ""

          Response.new(http.request(request))
        end
      end

      def http_request(method, uri)
        type = {
          get: Net::HTTP::Get,
          head: Net::HTTP::Head,
          post: Net::HTTP::Post,
        }.fetch(method, nil)

        raise "Unknown HTTP method #{method}!" unless type

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
          raise Http.error(self) unless request.redirectable?

          request.redirect_to(location)
        elsif see_other?
          request.see_other(location)
        else
          request
        end
      end

      def location
        @response["location"]
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
      attr_reader :http_code, :response

      def self.from_response(http_response)
        body = FFI_Yajl::Parser.parse(http_response.body)
        new(body['message'], http_response.code, body)
      end

      def initialize(message, http_code, response)
        super(message)
        @http_code = http_code
        @response = response
      end
    end
  end
end
