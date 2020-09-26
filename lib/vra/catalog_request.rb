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
require "vra/catalog_item"

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end
end

module Vra
  class CatalogRequest
    attr_reader :catalog_id, :catalog_item, :client, :custom_fields
    attr_writer :subtenant_id, :template_payload
    attr_accessor :cpus, :memory, :shirt_size,  :requested_for, :lease_days, :notes

    def initialize(client, catalog_id, opts = {})
      @client            = client
      @catalog_id        = catalog_id
      @cpus              = opts[:cpus]
      @memory            = opts[:memory]
      @shirt_size        = opts[:shirt_size]
      @requested_for     = opts[:requested_for]
      @lease_days        = opts[:lease_days]
      @notes             = opts[:notes]
      @subtenant_id      = opts[:subtenant_id]
      @additional_params = opts[:additional_params] || Vra::RequestParameters.new
      @catalog_item = Vra::CatalogItem.new(client, id: catalog_id)
    end

    # @param payload_file [String] - A json payload that represents the catalog template you want to merge with this request
    # @param client [Vra::Client] - a vra client object
    # @return [Vra::CatalogRequest] - a request with the given payload merged
    def self.request_from_payload(client, payload_file)
      hash_payload = JSON.parse(File.read(payload_file))
      catalog_id = hash_payload["catalogItemId"]
      blueprint_name = hash_payload["data"].select { |_k, v| v.is_a?(Hash) }.keys.first
      blueprint_data = hash_payload["data"][blueprint_name]
      opts = {}
      opts[:cpus] = blueprint_data["data"]["cpu"]
      opts[:memory] = blueprint_data["data"]["memory"]
      opts[:shirt_size] = blueprint_data["data"]["size"]
      opts[:requested_for] = hash_payload["requestedFor"]
      opts[:lease_days] = blueprint_data.fetch("leaseDays", nil) || hash_payload["data"].fetch("_lease_days", 1)
      opts[:description] = hash_payload["description"]
      opts[:subtenant_id] = hash_payload["businessGroupId"]
      cr = Vra::CatalogRequest.new(client, catalog_id, opts)
      cr.template_payload = File.read(payload_file)
      cr
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
      %i{catalog_id cpus memory requested_for subtenant_id }.each do |param|
        missing_params << param.to_s if send(param).nil?
      end

      raise ArgumentError, "Unable to submit request, required param(s) missing => #{missing_params.join(", ")}" unless missing_params.empty?
    end

    # @return [String] - the current catalog template payload merged with the settings applied from this request
    # @param [String] - A json payload that represents the catalog template you want to merge with this request
    def merge_payload(payload)
      hash_payload = JSON.parse(payload)
      blueprint_name = hash_payload["data"].select { |_k, v| v.is_a?(Hash) }.keys.first
      hash_payload["data"][blueprint_name]["data"]["cpu"] = @cpus
      hash_payload["data"][blueprint_name]["data"]["memory"] = @memory
      hash_payload["data"][blueprint_name]["data"]["size"] = @shirt_size
      hash_payload["requestedFor"] = @requested_for
      hash_payload["data"]["_leaseDays"] = @lease_days
      hash_payload["description"] = @notes
      hash_payload["data"] = hash_payload["data"].deep_merge(parameters["data"]) unless parameters.empty?
      hash_payload.to_json
    end

    # @return [String] - the current catalog template payload merged with the settings applied from this request
    def merged_payload
      merge_payload(template_payload)
    end

    # @return [String] - the current catalog template payload from VRA or custom payload set in JSON format
    def template_payload
      @template_payload ||= Vra::CatalogItem.dump_template(client, @catalog_id)
    end

    # @return [Vra::Request] - submits and returns the request, validating before hand
    def submit
      validate_params!
      begin
        post_response = client.http_post("/catalog-service/api/consumer/entitledCatalogItems/#{@catalog_id}/requests", merged_payload)
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.errors.join(", ")}"
      rescue
        raise
      end
      request_id = JSON.parse(post_response.body)["id"]
      Vra::Request.new(client, request_id)
    end
  end
end
