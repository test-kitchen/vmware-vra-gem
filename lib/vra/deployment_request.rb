# frozen_string_literal: true
#
# Author:: Ashique Saidalavi (<ashique.saidalavi@progress.com>)
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

module Vra
  # class that handles the deployment request with catalog
  class DeploymentRequest
    attr_reader :catalog_id

    def initialize(client, catalog_id, opts)
      @client     = client
      @catalog_id = catalog_id
      validate!

      @image_mapping  = opts[:image_mapping]
      @name           = opts[:name]
      @flavor_mapping = opts[:flavor_mapping]
      @project_id     = opts[:project_id]
      @version        = opts[:version]
      @count          = opts[:count] || 1
    end

    def submit!
      begin
        response = send_request!
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.errors.join(', ')}"
      rescue StandardError => e
        raise e
      end

      request_id = FFI_Yajl::Parser.parse(response.body)['id']
      Vra::Deployment.new(client, request_id)
    end

    private

    attr_reader :client, :image_mapping, :name,
                :flavor_mapping, :project_id, :version,
                :count

    def validate!
      missing_params = []
      %i[image_mapping flavor_mapping name project_id version].each do |arg|
        missing_params << arg unless opts.key?(arg)
      end

      return if missing_params.empty?

      raise ArgumentError, "Unable to submit request, required param(s) missing => #{missing_params.join(', ')}"
    end

    def send_request!
      client.http_post!(
        "/catalog/api/items/#{catalog_id}/request",
        FFI_Yajl::Encoder.encode(request_payload)
      )
    end

    def request_payload
      {
        'deploymentName': "'#{name}'",
        'projectId': project_id,
        'version': version,
        'inputs': {
          'count': count,
          'image': image_mapping,
          'flavor': flavor_mapping
        }
      }
    end
  end
end
