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
    attr_reader :catalog_id, :client, :custom_fields
    attr_writer :subtenant_id
    attr_accessor :cpus, :memory, :requested_for, :lease_days, :notes

    def initialize(client, catalog_id, opts={})
      @client            = client
      @catalog_id        = catalog_id
      @cpus              = opts[:cpus]
      @memory            = opts[:memory]
      @requested_for     = opts[:requested_for]
      @lease_days        = opts[:lease_days]
      @notes             = opts[:notes]
      @subtenant_id      = opts[:subtenant_id]
      @catalog_details   = {}
      @additional_params = Vra::RequestParameters.new
    end

    def set_parameter(key, type, value)
      @additional_params.set(key, type, value)
    end

    def delete_parameter(key)
      @additional_params.delete(key)
    end

    def parameters
      @additional_params.all_entries
    end

    def subtenant_id
      @subtenant_id || @catalog_details[:subtenant_id]
    end

    def validate_params!
      missing_params = []
      [ :catalog_id, :cpus, :memory, :requested_for, :subtenant_id ].each do |param|
        missing_params << param.to_s if send(param).nil?
      end

      raise ArgumentError, "Unable to submit request, required param(s) missing => #{missing_params.join(', ')}" unless missing_params.empty?
    end

    def fetch_catalog_item
      begin
        response = client.http_get("/catalog-service/api/consumer/catalogItems/#{@catalog_id}")
      rescue Vra::Exception::HTTPNotFound
        raise Vra::Exception::NotFound, "catalog ID #{@catalog_id} does not exist"
      end

      item = FFI_Yajl::Parser.parse(response.body)

      @catalog_details[:tenant_id]    = item['organization']['tenantRef']
      @catalog_details[:subtenant_id] = item['organization']['subtenantRef']
      @catalog_details[:blueprint_id] = item['providerBinding']['bindingId']
    end

    def catalog_detail(key)
      @catalog_details[key]
    end

    def request_payload
      fetch_catalog_item if @catalog_details.empty?

      payload = {
        '@type' => 'CatalogItemRequest',
        'catalogItemRef' => {
          'id' => @catalog_id
        },
        'organization' => {
          'tenantRef'    => catalog_detail(:tenant_id),
          'subtenantRef' => subtenant_id
        },
        'requestedFor' => @requested_for,
        'state' => 'SUBMITTED',
        'requestNumber' => 0,
        'requestData' => {
          'entries' => [
            Vra::RequestParameter.new('provider-blueprintId', 'string', catalog_detail(:blueprint_id)).to_h,
            Vra::RequestParameter.new('provider-provisioningGroupId', 'string', subtenant_id).to_h,
            Vra::RequestParameter.new('requestedFor', 'string', @requested_for).to_h,
            Vra::RequestParameter.new('provider-VirtualMachine.CPU.Count', 'integer', @cpus).to_h,
            Vra::RequestParameter.new('provider-VirtualMachine.Memory.Size', 'integer', @memory).to_h,
            Vra::RequestParameter.new('provider-VirtualMachine.LeaseDays', 'integer', @lease_days).to_h,
            Vra::RequestParameter.new('provider-__Notes', 'string', @notes).to_h
          ]
        }
      }

      parameters.each do |entry|
        payload['requestData']['entries'] << entry.to_h
      end

      payload
    end

    def submit
      fetch_catalog_item if @catalog_details.empty?
      validate_params!

      begin
        response = client.http_post('/catalog-service/api/consumer/requests', request_payload.to_json)
      rescue Vra::Exception::HTTPError => e
        raise Vra::Exception::RequestError, "Unable to submit request: #{e.errors.join(', ')}"
      rescue
        raise
      end

      request_id = response.headers[:location].split('/')[-1]
      Vra::Request.new(client, request_id)
    end
  end
end
