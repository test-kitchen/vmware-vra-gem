# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2022 Chef Software, Inc.
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

require "ffi_yajl" unless defined?(FFI_Yajl)

module Vra
  class Resource
    VM_TYPES = %w[
      Cloud.vSphere.Machine
      Cloud.Machine
    ].freeze

    attr_reader :client, :deployment_id, :id, :resource_data

    def initialize(client, deployment_id, opts = {})
      @client           = client
      @deployment_id    = deployment_id
      @id               = opts[:id]
      @resource_data    = opts[:data]
      @resource_actions = []

      raise ArgumentError, 'must supply an id or a resource data hash' if @id.nil? && @resource_data.nil?
      raise ArgumentError, 'must supply an id OR a resource data hash, not both' if !@id.nil? && !@resource_data.nil?

      if @resource_data.nil?
        fetch_resource_data
      else
        @id = @resource_data['id']
      end
    end

    def fetch_resource_data
      @resource_data = client.get_parsed("/deployment/api/deployments/#{deployment_id}/resources/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "resource ID #{@id} does not exist"
    end

    alias refresh fetch_resource_data

    def name
      resource_data['name']
    end

    def status
      resource_data['syncStatus']
    end

    def properties
      resource_data['properties']
    end

    def vm?
      VM_TYPES.include?(resource_data['type'])
    end

    def owner_names
      properties['Owner']
    end

    def project_id
      properties['project']
    end

    def network_interfaces
      return unless vm?

      network_list = properties['networks']
      return if network_list.nil?

      network_list.each_with_object([]) do |item, nics|
        nics << {
          'NETWORK_NAME' => item['name'],
          'NETWORK_ADDRESS' => item['address'],
          'NETWORK_MAC_ADDRESS' => item['mac_address']
        }
      end
    end

    def ip_addresses
      return if !vm? || network_interfaces.nil?

      properties['address']
    end
  end
end
