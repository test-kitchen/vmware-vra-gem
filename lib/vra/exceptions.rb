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

require "ffi_yajl"

module Vra
  module Exception
    class DuplicateItemsDetected < RuntimeError; end
    class NotFound < RuntimeError; end
    class RequestError < RuntimeError; end
    class Unauthorized < RuntimeError; end

    class HTTPError < RuntimeError
      attr_accessor :klass, :code, :body, :errors, :path
      def initialize(opts = {})
        @code = opts[:code]
        @body = opts[:body]
        @path = opts[:path]
        @klass = opts[:klass]
        @errors = []

        parse_errors
      end

      def parse_errors
        begin
          data = FFI_Yajl::Parser.parse(@body)
        rescue FFI_Yajl::ParseError
          return
        end

        return if data.nil?
        return unless data["errors"].respond_to?(:each)

        data["errors"].each do |error|
          if error["systemMessage"]
            @errors << error["systemMessage"]
          else
            @errors << error["message"]
          end
        end
      end
    end

    class HTTPNotFound < HTTPError; end
  end
end
