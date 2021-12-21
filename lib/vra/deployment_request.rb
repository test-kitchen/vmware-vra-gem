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

# Overriding the hash object to add the deep_merge method
class ::Hash
  def deep_merge(second)
    merger = proc { |_key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end
end

module Vra
  # class that handles the deployment request with catalog
  class DeploymentRequest
    attr_reader :catalog_id
    attr_accessor :image_mapping, :name, :flavor_mapping,
                  :project_id, :version, :count

    def initialize(client, catalog_id, opts = {})
      @client            = client
      @catalog_id        = catalog_id
      @image_mapping     = opts[:image_mapping]
      @name              = opts[:name]
      @flavor_mapping    = opts[:flavor_mapping]
      @project_id        = opts[:project_id]
      @version           = opts[:version]
      @count             = opts[:count] || 1
      @additional_params = opts[:additional_params] || Vra::RequestParameters.new
    end

    def submit
      validate!
      begin
        response = send_request!
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.message}, trace: #{e.errors.join(', ')}"
      rescue StandardError => e
        raise e, e.message
      end

      request_id = FFI_Yajl::Parser.parse(response)[0]['deploymentId']
      Vra::Deployment.new(client, id: request_id)
    end

    def set_parameter(key, type, value)
      @additional_params.set(key, type, value)
    end

    def set_parameters(key, value_data)
      @additional_params.set_parameters(key, value_data)
    end

    def delete_parameter(key)
      @additional_params.delete(key)
    end

    def parameters
      @additional_params.to_vra
    end

    private

    attr_reader :client

    def validate!
      missing_params = []
      %i[image_mapping flavor_mapping name project_id version].each do |arg|
        missing_params << arg if send(arg).nil?
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
        'deploymentName': name,
        'projectId': project_id,
        'version': version,
        'inputs': {
          'count': count,
          'image': image_mapping,
          'flavor': flavor_mapping
        }
      }.deep_merge(parameters)
    end
  end
end
