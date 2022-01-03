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

shared_examples 'refresh_trigger_method' do |method|
  it 'calls #refresh_if_needed' do
    expect(request).to receive(:refresh_if_empty)
    request.send(method)
  end

  it 'returns nil if request data is empty' do
    allow(request).to receive(:refresh_if_empty)
    allow(request).to receive(:request_empty?).and_return true
    expect(request.send(method)).to eq nil
  end
end

describe Vra::Request do
  let(:client) do
    Vra::Client.new(
      username: 'user@corp.local',
      password: 'password',
      tenant: 'tenant',
      base_url: 'https://vra.corp.local'
    )
  end

  let(:deployment_id) { 'dep-123' }

  let(:request_id) { 'req-123' }

  let(:completed_payload) do
    JSON.parse(File.read('spec/fixtures/resource/sample_dep_request.json'))
  end

  let(:in_progress_payload) do
    JSON.parse(File.read('spec/fixtures/resource/sample_dep_request.json'))
        .merge('status' => 'IN_PROGRESS')
  end

  let(:request) { Vra::Request.new(client, deployment_id, data: in_progress_payload) }

  before(:each) do
    allow(client).to receive(:authorized?).and_return(true)
  end

  describe '#initialize' do
    it 'sets the id' do
      allow(client).to receive(:get_parsed).and_return(completed_payload)

      req = described_class.new(client, deployment_id, id: request_id)
      expect(req.id).to eq(request_id)
    end

    it 'sets the attributes correctly' do
      allow(client).to receive(:get_parsed).and_return(completed_payload)

      req = described_class.new(client, deployment_id, id: request_id)
      expect(req.status).to eq('SUCCESSFUL')
      expect(req.completed?).to be_truthy
      expect(req.failed?).to be_falsey
      expect(req.name).to eq('Create')
      expect(req.requested_by).to eq('admin')
    end
  end

  describe '#refresh' do
    it 'calls the request API endpoint' do
      expect(client).to receive(:get_parsed)
        .with("/deployment/api/deployments/#{deployment_id}/requests/#{request_id}?deleted=true")
        .and_return(in_progress_payload)

      request.refresh
    end

    it 'should raise an exception if the resource not found' do
      allow(client).to receive(:get_parsed).and_raise(Vra::Exception::HTTPNotFound)

      expect { request.refresh }
        .to raise_error(Vra::Exception::NotFound)
        .with_message("request ID #{request_id} is not found")
    end
  end

  describe '#refresh_if_empty' do
    context 'request data is not empty' do
      it 'does not call #refresh' do
        allow(request).to receive(:request_empty?).and_return(false)
        expect(request).to_not receive(:refresh)
      end
    end
  end

  describe '#status' do
    it_behaves_like 'refresh_trigger_method', :status
  end

  describe '#completed?' do
    context 'when the request is neither successful or failed yet' do
      it 'returns false' do
        allow(request).to receive(:successful?).and_return(false)
        allow(request).to receive(:failed?).and_return(false)
        expect(request.completed?).to eq false
      end
    end

    context 'when the request is successful' do
      it 'returns true' do
        allow(request).to receive(:successful?).and_return(true)
        allow(request).to receive(:failed?).and_return(false)
        expect(request.completed?).to eq true
      end
    end

    context 'when the request failed' do
      it 'returns true' do
        allow(request).to receive(:successful?).and_return(false)
        allow(request).to receive(:failed?).and_return(true)
        expect(request.completed?).to eq true
      end
    end
  end
end
