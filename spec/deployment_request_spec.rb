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

require 'spec_helper'

describe Vra::DeploymentRequest do
  let(:client) do
    Vra::Client.new(
      username: 'user@corp.local',
      password: 'password',
      tenant: 'tenant',
      base_url: 'https://vra.corp.local'
    )
  end

  let(:catalog_id) { 'cat-123456' }

  let(:request_payload) do
    {
      image_mapping: 'Centos Image',
      name: 'test deployment',
      flavor_mapping: 'Small',
      version: '1',
      project_id: 'pro-123'
    }
  end

  describe '#initialize' do
    it 'should raise errors for missing arguments' do
      request = described_class.new(
        client,
        catalog_id,
        request_payload
      )

      expect(request.name).to eq('test deployment')
      expect(request.image_mapping).to eq('Centos Image')
      expect(request.flavor_mapping).to eq('Small')
      expect(request.version).to eq('1')
      expect(request.count).to eq(1)
    end
  end

  describe '#validate!' do
    it 'should return error if params are missing' do
      request = described_class.new(client, catalog_id)
      expect { request.send(:validate!) }.to raise_error(ArgumentError)

      request.image_mapping  = 'Centos Image'
      request.name           = 'test deployment'
      request.flavor_mapping = 'Small'
      request.version        = '1'
      request.project_id     = 'pro-123'

      expect { request.send(:validate!) }.not_to raise_error(ArgumentError)
    end
  end

  describe '#additional parameters' do
    let(:request) do
      described_class.new(client, catalog_id, request_payload)
    end

    context 'set_parameter' do
      it 'should set the parameter' do
        request.set_parameter('hardware-config', 'stirng', 'Small')

        expect(request.parameters).to eq({ inputs: { 'hardware-config' => 'Small' } })
        expect(request.parameters[:inputs].count).to be(1)
      end
    end

    context 'delete_parameter' do
      before(:each) do
        request.set_parameter('hardware-config', 'string', 'small')
      end

      it 'should delete the existing parameter' do
        expect(request.parameters[:inputs].count).to be(1)
        request.delete_parameter('hardware-config')
        expect(request.parameters[:inputs].count).to be(0)
      end
    end
  end

  describe '#submit' do
    let(:request) do
      described_class.new(client, catalog_id, request_payload)
    end

    before(:each) do
      allow(client).to receive(:authorized?).and_return(true)
    end

    it 'should call the validate before submit' do
      expect(request).to receive(:validate!)
      stub_request(:post, client.full_url('/catalog/api/items/cat-123456/request'))
        .to_return(status: 200, body: '[{"deploymentId": "123"}]', headers: {})
      allow(Vra::Deployment).to receive(:new)

      request.submit
    end

    it 'should call the api to submit the deployment request' do
      response = double('response', body: '[{"deploymentId": "123"}]', success?: true)
      allow(client)
        .to receive(:http_post)
        .with(
          "/catalog/api/items/#{catalog_id}/request",
          {
            deploymentName: 'test deployment',
            projectId: 'pro-123',
            version: '1',
            inputs: {
              count: 1,
              image: 'Centos Image',
              flavor: 'Small'
            }
          }.to_json
        )
        .and_return(response)
      allow(Vra::Deployment).to receive(:new)

      request.submit
    end
  end
end
