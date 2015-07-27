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
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:request_id) { '2c3df007-b1c4-4687-b332-310089c4851d' }

  let(:in_progress_payload) do
    {
      'phase' => 'IN_PROGRESS',
      'requestCompletion' => {
        'requestCompletionState' => nil,
        'completionDetails' => nil
      }
    }
  end

  let(:completed_payload) do
    {
      'phase' => 'SUCCESSFUL',
      'requestCompletion' => {
        'requestCompletionState' => 'SUCCESSFUL',
        'completionDetails' => 'Request succeeded. Created test-machine.'
      }
    }
  end

  let(:request) { Vra::Request.new(client, request_id) }

  describe '#initialize' do
    it 'sets the id' do
      expect(request.id).to eq request_id
    end
  end

  describe '#refresh' do
    it 'calls the request API endpoint' do
      expect(client).to receive(:http_get!)
        .with("/catalog-service/api/consumer/requests/#{request_id}")
        .and_return(in_progress_payload.to_json)

      request.refresh
    end
  end

  describe '#refresh_if_empty' do
    context 'request data is empty' do
      it 'calls #refresh' do
        expect(request).to receive(:refresh)
        request.refresh_if_empty
      end
    end

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

  describe '#completion_state' do
    it_behaves_like 'refresh_trigger_method', :completion_state
  end

  describe '#completion_details' do
    it_behaves_like 'refresh_trigger_method', :completion_details
  end

  describe '#resources' do
    it 'calls the requests resources API endpoint' do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog-service/api/consumer/requests/#{request_id}/resources")
        .and_return([])

      request.resources
    end
  end
end
