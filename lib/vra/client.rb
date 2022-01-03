# frozen_string_literal: true
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

require 'ffi_yajl' unless defined?(FFI_Yajl)
require 'passwordmasker'
require 'vra/http'

module Vra
  class Client
    ACCESS_TOKEN_URL = '/csp/gateway/am/api/login?access_token'
    ROLES_URL = '/csp/gateway/am/api/loggedin/user/orgs'

    attr_accessor :page_size

    def initialize(opts)
      @base_url      = opts[:base_url]
      @username      = opts[:username]
      @password      = PasswordMasker.new(opts[:password])
      @tenant        = opts[:tenant]
      @verify_ssl    = opts.fetch(:verify_ssl, true)
      @refresh_token = PasswordMasker.new(nil)
      @access_token  = PasswordMasker.new(nil)
      @page_size     = opts.fetch(:page_size, 20)

      validate_client_options!
    end

    #########################
    #
    # methods to other classes
    #

    def catalog
      @catalog ||= Vra::Catalog.new(self)
    end

    def deployments
      @deployments ||= Vra::Deployments.new(self)
    end

    #########################
    #
    # client methods
    #

    def access_token
      @access_token.value
    end

    def refresh_token
      @refresh_token.value
    end

    def access_token=(value)
      @access_token.value = value
    end

    def refresh_token=(value)
      puts "inside the setter method"
      @refresh_token.value = value
    end

    def token_params
      {
        'username': @username,
        'password': @password.value,
        'tenant': @tenant
      }
    end

    def request_headers
      headers                   = {}
      headers['Accept']         = 'application/json'
      headers['Content-Type']   = 'application/json'
      headers['csp-auth-token'] = @access_token.value unless @access_token.value.nil?

      headers
    end

    def authorize!
      generate_access_token unless authorized?

      raise Vra::Exception::Unauthorized, 'Unable to authorize against vRA' unless authorized?
    end

    def authorized?
      return false if @access_token.value.nil?

      response = http_head(ROLES_URL, :skip_auth)
      response.success?
    end

    def generate_access_token
      @access_token.value = nil
      validate_client_options!

      response = http_post(ACCESS_TOKEN_URL,
                           FFI_Yajl::Encoder.encode(token_params),
                           :skip_auth)
      raise Vra::Exception::Unauthorized, "Unable to get bearer token: #{response.body}" unless response.success_ok?

      response_body = FFI_Yajl::Parser.parse(response.body)
      @access_token.value = response_body['access_token']
      @refresh_token.value = response_body['refresh_token']
    end

    def full_url(path)
      "#{@base_url}#{path}"
    end

    def http_fetch(method, path, skip_auth = nil)
      authorize! unless skip_auth

      response = Vra::Http.execute(method: method,
                                   url: full_url(path),
                                   headers: request_headers,
                                   verify_ssl: @verify_ssl)
    rescue => e
      raise_http_exception(e, path)
    else
      response
    end

    def http_head(path, skip_auth = nil)
      http_fetch(:head, path, skip_auth)
    end

    def http_get(path, skip_auth = nil)
      http_fetch(:get, path, skip_auth)
    end

    def http_get!(path)
      response = http_get(path)
      response.body
    end

    def http_delete(path, skip_auth = nil)
      http_fetch(:delete, path, skip_auth)
    end

    def get_parsed(path)
      FFI_Yajl::Parser.parse(http_get!(path))
    end

    def http_get_paginated_array!(path, filter = nil)
      items = []
      page = 0
      base_path = path + "?$top=#{page_size}"
      base_path += "&#{filter}" if filter

      loop do
        response = get_parsed("#{base_path}&$skip=#{page * page_size}")
        items += response["content"]

        page += 1
        break if page >= response["totalPages"]
      end

      if items.uniq!
        raise Vra::Exception::DuplicateItemsDetected,
              "Duplicate items were returned by the vRA API. " \
              "Increase your page size to avoid this vRA API bug. " \
              "See https://github.com/chef-partners/vmware-vra-gem#pagination " \
              "for more information."
      end

      items
    end

    def http_post(path, payload, skip_auth = nil)
      authorize! unless skip_auth

      response = Vra::Http.execute(method: :post,
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

      klass = if caught_exception.http_code == 404
                Vra::Exception::HTTPNotFound
              else
                Vra::Exception::HTTPError
              end

      exception = klass.new(code: caught_exception.http_code,
                            body: caught_exception.response,
                            klass: caught_exception.class,
                            path: path)

      message = exception.errors.empty? ? caught_exception.message : exception.errors.join(", ")
      raise exception, message
    end

    def validate_client_options!
      raise ArgumentError, "Username and password are required" if @username.nil? || @password.value.nil?
      raise ArgumentError, "A tenant is required" if @tenant.nil?
      raise ArgumentError, "A base URL is required" if @base_url.nil?
      raise ArgumentError, "Base URL #{@base_url} is not a valid URI." unless valid_uri?(@base_url)
    end

    def valid_uri?(uri)
      uri = URI.parse(uri)
      uri.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

    def fetch_subtenant_items(tenant, subtenant_name)
      http_get("/identity/api/tenants/#{tenant}/subtenants?%24filter=name+eq+'#{subtenant_name}'")
    end

  end
end
