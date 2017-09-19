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

module Vra
  class CatalogRequest
    attr_reader :catalog_id, :catalog_item, :client, :custom_fields
    attr_writer :subtenant_id
    attr_accessor :cpus, :memory, :requested_for, :lease_days, :notes

    def initialize(client, catalog_id, opts = {})
      @client            = client
      @catalog_id        = catalog_id
      @cpus              = opts[:cpus]
      @memory            = opts[:memory]
      @requested_for     = opts[:requested_for]
      @lease_days        = opts[:lease_days]
      @notes             = opts[:notes]
      @subtenant_id      = opts[:subtenant_id]
      @additional_params = opts[:additional_params] || Vra::RequestParameters.new

      @catalog_item = Vra::CatalogItem.new(client, id: catalog_id)
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

    def subtenant_id
      @subtenant_id || catalog_item.subtenant_id
    end

    def validate_params!
      missing_params = []
      [ :catalog_id, :cpus, :memory, :requested_for, :subtenant_id ].each do |param|
        missing_params << param.to_s if send(param).nil?
      end

      raise ArgumentError, "Unable to submit request, required param(s) missing => #{missing_params.join(', ')}" unless missing_params.empty?
    end

    def submit
      validate_params!

      begin
        response = client.http_get("/catalog-service/api/consumer/entitledCatalogItems/#{@catalog_id}/requests/template")
        post_response = client.http_post("/catalog-service/api/consumer/entitledCatalogItems/#{@catalog_id}/requests", response.body)
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.errors.join(', ')}"
      rescue
        raise
      end

      request_id = JSON.parse(post_response.body)["id"]
      Vra::Request.new(client, request_id)
    end

    def deep_merge(first, second)
      merger = proc do |key, v1, v2|
        if Hash === v1 && Hash === v2
          v1.merge(v2, &merger)
        elsif Array === v1 && Array === v2
          v1 | v2
        elsif [:undefined, nil, :nil].include?(v2)
          v1
        else
          v2
        end
      end
      first.merge(second.to_h, &merger)
    end

    private :deep_merge
  end
end
