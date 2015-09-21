#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'ffi_yajl'
require 'rest-client'
require 'passwordmasker'

module Vra
  # rubocop:disable ClassLength
  class Client
    attr_accessor :bearer_token, :page_size

    def initialize(opts)
      @base_url     = opts[:base_url]
      @username     = opts[:username]
      @password     = PasswordMasker.new(opts[:password])
      @tenant       = opts[:tenant]
      @verify_ssl   = opts.fetch(:verify_ssl, true)
      @bearer_token = PasswordMasker.new(nil)
      @page_size    = opts.fetch(:page_size, 20)

      validate_client_options!
    end

    #########################
    #
    # methods to other classes
    #

    def catalog
      Vra::Catalog.new(self)
    end

    def requests(*args)
      Vra::Requests.new(self, *args)
    end

    def resources(*args)
      Vra::Resources.new(self, *args)
    end

    #########################
    #
    # client methods
    #

    def bearer_token_request_body
      {
        'username' => @username,
        'password' => @password.value,
        'tenant'   => @tenant
      }
    end

    def request_headers
      headers = {}
      headers['Accept']        = 'application/json'
      headers['Content-Type']  = 'application/json'
      headers['Authorization'] = "Bearer #{@bearer_token.value}" unless @bearer_token.value.nil?
      headers
    end

    def authorize!
      generate_bearer_token unless authorized?

      raise Vra::Exception::Unauthorized, 'Unable to authorize against vRA' unless authorized?
    end

    def authorized?
      return false if @bearer_token.value.nil?

      response = http_head("/identity/api/tokens/#{@bearer_token.value}", :skip_auth)
      if response.code == 204
        true
      else
        false
      end
    end

    def generate_bearer_token
      @bearer_token.value = nil
      validate_client_options!

      response = http_post('/identity/api/tokens', bearer_token_request_body.to_json, :skip_auth)
      if response.code != 200
        raise Vra::Exception::Unauthorized, "Unable to get bearer token: #{response.body}"
      end

      @bearer_token.value = FFI_Yajl::Parser.parse(response.body)['id']
    end

    def full_url(path)
      "#{@base_url}#{path}"
    end

    def http_head(path, skip_auth=nil)
      authorize! unless skip_auth

      response = RestClient::Request.execute(method: :head,
                                             url: full_url(path),
                                             headers: request_headers,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise Vra::Exception::HTTPError, "head #{path} failed: #{e.class}: #{e.message}"
    else
      response
    end

    def http_get(path, skip_auth=nil)
      authorize! unless skip_auth

      response = RestClient::Request.execute(method: :get,
                                             url: full_url(path),
                                             headers: request_headers,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      response
    end

    def http_get!(path)
      response = http_get(path)
      response.body
    end

    def http_get_paginated_array!(path)
      items = []
      page = 1
      base_path = path + "?limit=#{page_size}"

      loop do
        response = FFI_Yajl::Parser.parse(http_get!("#{base_path}&page=#{page}"))
        items += response['content']

        break if page >= response['metadata']['totalPages']
        page += 1
      end

      items
    end

    def http_post(path, payload, skip_auth=nil)
      authorize! unless skip_auth

      response = RestClient::Request.execute(method: :post,
                                             url: full_url(path),
                                             headers: request_headers,
                                             payload: payload,
                                             verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      response
    end

    def http_post!(path, payload)
      response = http_post(path, payload)
      response.body
    end

    def raise_http_exception(caught_exception, path)
      raise unless caught_exception.respond_to?(:http_code)

      if caught_exception.http_code == 404
        klass = Vra::Exception::HTTPNotFound
      else
        klass = Vra::Exception::HTTPError
      end

      exception = klass.new(code: caught_exception.http_code,
                            body: caught_exception.response,
                            klass: caught_exception.class,
                            path: path)

      message = exception.errors.empty? ? caught_exception.message : exception.errors.join(', ')
      raise exception, message
    end

    def validate_client_options!
      raise ArgumentError, 'Username and password are required' if @username.nil? || @password.value.nil?
      raise ArgumentError, 'A tenant is required' if @tenant.nil?
      raise ArgumentError, 'A base URL is required' if @base_url.nil?
      raise ArgumentError, "Base URL #{@base_url} is not a valid URI." unless valid_uri?(@base_url)
    end

    def valid_uri?(uri)
      uri = URI.parse(uri)
      uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end
  end
end
