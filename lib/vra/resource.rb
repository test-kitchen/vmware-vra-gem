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
  class Resource
    attr_reader :client, :id, :resource_data

    def initialize(client, opts)
      @client           = client
      @id               = opts[:id]
      @resource_data    = opts[:data]
      @resource_actions = []

      if @id.nil? && @resource_data.nil?
        raise ArgumentError, "must supply an id or a resource data hash"
      end

      if !@id.nil? && !@resource_data.nil?
        raise ArgumentError, "must supply an id OR a resource data hash, not both"
      end

      if @resource_data.nil?
        fetch_resource_data
      else
        @id = @resource_data["id"]
      end
    end

    def fetch_resource_data
      @resource_data = client.get_parsed("/catalog-service/api/consumer/resources/#{@id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "resource ID #{@id} does not exist"
    end
    alias refresh fetch_resource_data

    def name
      resource_data["name"]
    end

    def description
      resource_data["description"]
    end

    def status
      resource_data["status"]
    end

    def vm?
      %w{Infrastructure.Virtual Infrastructure.Cloud}.include?(resource_data["resourceTypeRef"]["id"])
    end

    def organization
      return {} if resource_data["organization"].nil?

      resource_data["organization"]
    end

    def tenant_id
      organization["tenantRef"]
    end

    def tenant_name
      organization["tenantLabel"]
    end

    def subtenant_id
      organization["subtenantRef"]
    end

    def subtenant_name
      organization["subtenantLabel"]
    end

    def catalog_item
      return {} if resource_data["catalogItem"].nil?

      resource_data["catalogItem"]
    end

    def catalog_id
      catalog_item["id"]
    end

    def catalog_name
      catalog_item["label"]
    end

    def owner_ids
      resource_data["owners"].map { |x| x["ref"] }
    end

    def owner_names
      resource_data["owners"].map { |x| x["value"] }
    end

    def machine_status
      status = resource_data["resourceData"]["entries"].find { |x| x["key"] == "MachineStatus" }
      raise "No MachineStatus entry available for resource" if status.nil?

      status["value"]["value"]
    end

    def machine_on?
      machine_status == "On"
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

      network_list = resource_data["resourceData"]["entries"].find { |x| x["key"] == "NETWORK_LIST" }
      return if network_list.nil?

      network_list["value"]["items"].each_with_object([]) do |item, nics|
        nic = {}
        item["values"]["entries"].each do |entry|
          key = entry["key"]
          value = entry["value"]["value"]
          nic[key] = value
        end

        nics << nic
      end
    end

    def ip_addresses
      return if !vm? || network_interfaces.nil?

      addrs = []

      request_id = @resource_data["requestId"]

      resource_views = @client.http_get("/catalog-service/api/consumer/requests/#{request_id}/resourceViews")

      data_zero = JSON.parse(resource_views.body)["content"][0]["data"]["ip_address"]
      data_one = JSON.parse(resource_views.body)["content"][1]["data"]["ip_address"]

      print "Waiting For vRA to collect the IP"
      while (data_zero == "" || data_one == "") && (data_zero.nil? || data_one.nil?)
        resource_views = @client.http_get("/catalog-service/api/consumer/requests/#{request_id}/resourceViews")
        data_zero = JSON.parse(resource_views.body)["content"][0]["data"]["ip_address"]
        data_one = JSON.parse(resource_views.body)["content"][1]["data"]["ip_address"]
        sleep 10
        print "."
      end

      ip_address = if JSON.parse(resource_views.body)["content"][0]["data"]["ip_address"].nil?
                     JSON.parse(resource_views.body)["content"][1]["data"]["ip_address"]
                   else
                     JSON.parse(resource_views.body)["content"][0]["data"]["ip_address"]
                   end

      addrs << ip_address
      addrs
    end

    def actions
      # if this Resource instance was created with data from a "all_resources" fetch,
      # it is likely missing operations data because the vRA API is not pleasant sometimes.
      fetch_resource_data if resource_data["resourceData"]["entries"].nil?

      resource_data["resourceData"]["entries"].each_with_object({}) do |pair, h|
        h[pair["key"]] = pair["value"]
      end
    end

    def action_id_by_name(name)
      return if actions.nil?

      action = actions.fetch(name)
    end

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
