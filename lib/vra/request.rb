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
  # class to represent the Deployment request
  class Request
    attr_reader :id, :deployment_id

    def initialize(client, deployment_id, opts = {})
      @client             = client
      @deployment_id      = deployment_id
      @id                 = opts[:id]
      @request_data       = opts[:data]

      if @request_data.nil?
        refresh
      else
        @id = @request_data['id']
      end
    end

    def requested_by
      request_data['requestedBy']
    end

    def name
      request_data['name']
    end

    def refresh
      @request_data = client.get_parsed("/deployment/api/deployments/#{deployment_id}/requests/#{id}?deleted=true")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "request ID #{@id} is not found"
    end

    def refresh_if_empty
      refresh if request_empty?
    end

    def request_empty?
      @request_data.nil?
    end

    def status
      refresh_if_empty
      return if request_empty?

      request_data['status']
    end

    def completed?
      successful? || failed?
    end

    def successful?
      status == 'SUCCESSFUL'
    end

    def failed?
      status == 'FAILED'
    end

    private

    attr_reader :request_data, :client
  end
end
