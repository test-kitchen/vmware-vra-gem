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
  # rubocop:disable ClassLength
  class Resource
    attr_reader :client, :id, :resource_data

    def initialize(client, opts)
      @client           = client
      @id               = opts[:id]
      @resource_data    = opts[:data]
      @resource_actions = []

      if @id.nil? && @resource_data.nil?
        raise ArgumentError, 'must supply an id or a resource data hash'
      end

      if ! @id.nil? && ! @resource_data.nil?
        raise ArgumentError, 'must supply an id OR a resource data hash, not both'
      end

      if @resource_data.nil?
        fetch_resource_data
      else
        @id = @resource_data['id']
      end
    end

    def fetch_resource_data
      @resource_data = JSON.load(client.http_get!("/catalog-service/api/consumer/resources/#{@id}"))
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, 'resource ID #{@id} does not exist'
    end

    def name
      @resource_data['name']
    end

    def status
      @resource_data['status']
    end

    def vm?
      @resource_data['resourceTypeRef']['id'] == 'Infrastructure.Virtual'
    end

    def tenant_id
      @resource_data['organization']['tenantRef']
    end

    def tenant_name
      @resource_data['organization']['tenantLabel']
    end

    def subtenant_id
      @resource_data['organization']['subtenantRef']
    end

    def subtenant_name
      @resource_data['organization']['subtenantLabel']
    end

    def catalog_id
      @resource_data['catalogItem']['id']
    end

    def catalog_name
      @resource_data['catalogItem']['label']
    end

    def network_interfaces
      return unless vm?

      network_list = @resource_data['resourceData']['entries'].find { |x| x['key'] == 'NETWORK_LIST' }
      return if network_list.nil?

      network_list['value']['items'].each_with_object([]) do |item, nics|
        nic = {}
        item['values']['entries'].each do |entry|
          key = entry['key']
          value = entry['value']['value']
          nic[key] = value
        end

        nics << nic
      end
    end

    def ip_addresses
      return if !vm? || network_interfaces.nil?

      addrs = []
      network_interfaces.each do |nic|
        next unless nic.key?('NETWORK_ADDRESS')
        addrs << nic['NETWORK_ADDRESS']
      end

      addrs
    end

    def actions
      # if this Resource instance was created with data from a "all_resources" fetch,
      # it is likely missing operations data because the vRA API is not pleasant sometimes.
      fetch_resource_data if @resource_data['operations'].nil?

      @resource_data['operations']
    end

    def action_id_by_name(name)
      return if actions.nil?

      action = actions.find { |x| x['name'] == name }
      return if action.nil?

      action['id']
    end

    def destroy
      action_id = action_id_by_name('Destroy')
      raise Vra::Exception::NotFound, "No destroy action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id)
    end

    def action_request_payload(action_id)
      {
        '@type' => 'ResourceActionRequest',
        'resourceRef' => {
          'id' => @id
        },
        'resourceActionRef' => {
          'id' => action_id
        },
        'organization' => {
          'tenantRef' => tenant_id,
          'tenantLabel' => tenant_name,
          'subtenantRef' => subtenant_id,
          'subtenantLabel' => subtenant_name
        },
        'state' => 'SUBMITTED',
        'requestNumber' => 0,
        'requestData' => {
          'entries' => []
        }
      }
    end

    def submit_action_request(action_id)
      payload = action_request_payload(action_id).to_json
      response = client.http_post('/catalog-service/api/consumer/requests', payload)
      request_id = response.headers[:location].split('/')[-1]
      Vra::Request.new(client, request_id)
    end
  end
end
