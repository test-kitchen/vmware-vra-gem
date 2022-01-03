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

require 'spec_helper'

describe ::Vra::Deployments do
  let(:client) do
    Vra::Client.new(
      username: 'user@corp.local',
      password: 'password',
      tenant: 'tenant',
      base_url: 'https://vra.corp.local'
    )
  end

  let(:deployment_response) do
    JSON.parse(File.read('spec/fixtures/resource/sample_deployment.json'))
  end

  before(:each) do
    allow(client).to receive(:authorized?).and_return(true)
  end

  describe '#by_id' do
    it 'should call the api to fetch the deployments' do
      expect(client).to receive(:get_parsed).and_return(deployment_response)

      described_class.by_id(client, 'dep-123')
    end

    it 'should return the deployment by id' do
      stub_request(:get, client.full_url('/deployment/api/deployments/dep-123'))
        .to_return(status: 200, body: deployment_response.to_json, headers: {})

      deployment = described_class.by_id(client, 'dep-123')
      expect(deployment).to be_an_instance_of(Vra::Deployment)
    end
  end

  describe '#all' do
    it 'should call the api to fetch all deployments' do
      expect(client)
        .to receive(:http_get_paginated_array!)
        .with('/deployment/api/deployments')
        .and_return([deployment_response])

      described_class.all(client)
    end

    it 'should return the Vra::Deployment object' do
      stub_request(:get, client.full_url('/deployment/api/deployments?$skip=0&$top=20'))
        .to_return(status: 200, body: { content: [deployment_response], totalPages: 1 }.to_json, headers: {})

      deployment = described_class.all(client).first
      expect(deployment).to be_an_instance_of(Vra::Deployment)
    end
  end

  describe 'called with client' do
    it 'should return the class object' do
      expect(client.deployments).to be_an_instance_of described_class
    end
  end
end
