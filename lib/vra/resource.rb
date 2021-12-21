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

require "ffi_yajl" unless defined?(FFI_Yajl)

module Vra
  class Resource
    attr_reader :client, :deployment_id, :id, :resource_data

    def initialize(client, deployment_id, opts)
      @client           = client
      @deployment_id    = deployment_id
      @id               = opts[:id]
      @resource_data    = opts[:data]
      @resource_actions = []

      if @id.nil? && @resource_data.nil?
        raise ArgumentError, 'must supply an id or a resource data hash'
      end

      if !@id.nil? && !@resource_data.nil?
        raise ArgumentError, 'must supply an id OR a resource data hash, not both'
      end

      if @resource_data.nil?
        fetch_resource_data
      else
        @id = @resource_data['id']
      end
    end

    # @param client [Vra::Client]
    # @param name [String] - the hostname of the client you wish to lookup
    # @preturn [Vra::Resource] - return nil if not found, otherwise the resource associated with the name
    def self.by_name(client, name)
      raise ArgumentError.new("name cannot be nil") if name.nil?
      raise ArgumentError.new("client cannot be nil") if client.nil?

      Resources.all(client).find { |r| r.name.downcase =~ /#{name.downcase}/ }
    end

    def fetch_resource_data
      @resource_data = client.get_parsed("/deployment/api/deployments/#{deployment_id}/resources/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "resource ID #{@id} does not exist"
    end
    alias refresh fetch_resource_data

    def name
      resource_data["name"]
    end

    def status
      resource_data['syncStatus']
    end

    def properties
      resource_data['properties']
    end

    # TODO: Confirm other vm resource types
    def vm?
      %w{Cloud.vSphere.Machine}.include?(resource_data['type'])
    end

    # def organization
    #   return {} if resource_data["organization"].nil?
    #
    #   resource_data["organization"]
    # end
    #
    # def tenant_id
    #   organization["tenantRef"]
    # end
    #
    # def tenant_name
    #   organization["tenantLabel"]
    # end
    #
    # def subtenant_id
    #   organization["subtenantRef"]
    # end
    #
    # def subtenant_name
    #   organization["subtenantLabel"]
    # end
    #
    # def catalog_item
    #   return {} if resource_data["catalogItem"].nil?
    #
    #   resource_data["catalogItem"]
    # end
    #
    # def catalog_id
    #   catalog_item["id"]
    # end
    #
    # def catalog_name
    #   catalog_item["label"]
    # end

    def owner_names
      properties['Owner']
    end

    def machine_status
      status = resource_data["resourceData"]["entries"].find { |x| x["key"] == "MachineStatus" }
      raise "No MachineStatus entry available for resource" if status.nil?

      status["value"]["value"]
    end

    def machine_on?
      status == 'SUCCESS'
    end

    def machine_off?
      machine_status == "Off"
    end

    def machine_turning_on?
      machine_status == "TurningOn" || machine_status == "MachineActivated"
    end

    def machine_turning_off?
      %w{TurningOff ShuttingDown}.include?(machine_status)
    end

    def machine_in_provisioned_state?
      machine_status == "MachineProvisioned"
    end

    def network_interfaces
      return unless vm?

      network_list = properties['networks']
      return if network_list.nil?

      network_list.each_with_object([]) do |item, nics|
        nic = {}
        nic[item['name']] = item['mac_address']

        nics << nic
      end
    end

    def ip_addresses
      return if !vm? || network_interfaces.nil?

      properties['address']
    end

    # TODO: Implement actions api
    # def actions
    #   # if this Resource instance was created with data from a "all_resources" fetch,
    #   # it is likely missing operations data because the vRA API is not pleasant sometimes.
    #   fetch_resource_data if resource_data["operations"].nil?
    #
    #   resource_data["operations"]
    # end

    # def action_id_by_name(name)
    #   return if actions.nil?
    #
    #   action = actions.find { |x| x["name"] == name }
    #   return if action.nil?
    #
    #   action["id"]
    # end

    def destroy
      action_id = action_id_by_name("Destroy")
      raise Vra::Exception::NotFound, "No destroy action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id)
    end

    def shutdown
      action_id = action_id_by_name("Shutdown")
      raise Vra::Exception::NotFound, "No shutdown action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id)
    end

    def poweroff
      action_id = action_id_by_name("Power Off")
      raise Vra::Exception::NotFound, "No power-off action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id)
    end

    def poweron
      action_id = action_id_by_name("Power On")
      raise Vra::Exception::NotFound, "No power-on action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id)
    end

    def action_request_payload(action_id)
      {
        "@type" => "ResourceActionRequest",
        "resourceRef" => {
          "id" => @id,
        },
        "resourceActionRef" => {
          "id" => action_id,
        },
        "organization" => {
          "tenantRef" => tenant_id,
          "tenantLabel" => tenant_name,
          "subtenantRef" => subtenant_id,
          "subtenantLabel" => subtenant_name,
        },
        "state" => "SUBMITTED",
        "requestNumber" => 0,
        "requestData" => {
          "entries" => [],
        },
      }
    end

    def submit_action_request(action_id)
      payload = action_request_payload(action_id).to_json
      response = client.http_post("/catalog-service/api/consumer/requests", payload)
      request_id = response.location.split("/")[-1]
      Vra::Request.new(client, request_id)
    end
  end
end
