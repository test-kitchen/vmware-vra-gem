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

require "ffi_yajl" unless defined?(FFI_Yajl)

module Vra
  # Class that represents the Deployment Object
  class Deployment
    INDEX_URL = '/deployment/api/deployments'

    attr_reader :id

    def initialize(client, opts = {})
      @client = client
      @id     = opts[:id]
      @data   = opts[:data]
      validate!

      if @data.nil?
        refresh
      elsif @id.nil?
        @id = @data['id']
      end
    end

    def name
      @data['name']
    end

    def description
      @data['description']
    end

    def org_id
      @data['orgId']
    end

    def blueprint_id
      @data['blueprintId']
    end

    def owner
      @data['ownedBy']
    end

    def status
      @data['status']
    end

    def successful?
      status == 'CREATE_SUCCESSFUL'
    end

    def failed?
      status == 'CREATE_FAILED'
    end

    def completed?
      successful? || failed?
    end

    def actions
      @actions = client.get_parsed("/deployment/api/deployments/#{id}/actions")
    end

    def action_id_by_name(action_name)
      action = actions.find { |x| x['name'] == action_name}
      return if action.nil?

      action['id']
    end

    def resources
      response = client.get_parsed("/deployment/api/deployments/#{id}/resources")

      response['content'].map! { |x| Vra::Resource.new(client, id, data: x) }
    end

    def requests
      response = client.get_parsed("/deployment/api/deployments/#{id}/requests")

      response['content'].map! { |x| Vra::Request.new(client, id, id: x['id'], data: x) }
    end

    def refresh
      @data = client.get_parsed("/deployment/api/deployments/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "deployment with ID #{id} does not exist"
    end

    def destroy(reason = '')
      action_id = action_id_by_name('Delete')
      raise Vra::Exception::NotFound, "No destroy action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id, reason)
    end

    def power_off(reason = '')
      action_id = action_id_by_name('PowerOff')
      raise Vra::Exception::NotFound, "No power-off action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id, reason)
    end

    def power_on(reason = nil)
      action_id = action_id_by_name('PowerOn')
      raise Vra::Exception::NotFound, "No power-on action found for resource #{@id}" if action_id.nil?

      submit_action_request(action_id, reason)
    end

    private

    attr_reader :client, :data

    def validate!
      raise ArgumentError, 'must supply id or data hash' if @id.nil? && @data.nil?
    end

    def submit_action_request(action_id, reason)
      response = client.http_post!("/deployment/api/deployments/#{id}/requests",
                                   FFI_Yajl::Encoder.encode(submit_action_payload(action_id, reason)))

      Vra::Request.new(client, id, data: FFI_Yajl::Parser.parse(response))
    end

    def submit_action_payload(action_id, reason)
      {
        "actionId": action_id,
        "inputs": {},
        "reason": reason
      }
    end
  end
end
