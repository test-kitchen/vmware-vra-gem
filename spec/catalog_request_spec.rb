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

describe Vra::CatalogRequest do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  context 'when no subtenant ID is provided' do
    let(:request) do
      client.catalog.request('catalog-12345',
                             cpus: 2,
                             memory: 1024,
                             lease_days: 15,
                             requested_for: 'tester@corp.local',
                             notes: 'test notes')
    end

    it 'uses the subtenant ID from the catalog item' do
      payload = {
        'organization' => {
          'tenantRef' => 'mytenant',
          'subtenantRef' => 'catalog_subtenant'
        },
        'providerBinding' => { 'bindingId' => 'blueprint-54321' }
      }

      response = double('response', code: 200, body: payload.to_json)
      allow(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_return(response)
      request.fetch_catalog_item

      expect(request.subtenant_id).to eq 'catalog_subtenant'
    end
  end

  context 'when subtenant is provided, and all shared tests' do
    let(:request) do
      client.catalog.request('catalog-12345',
                             cpus: 2,
                             memory: 1024,
                             lease_days: 15,
                             requested_for: 'tester@corp.local',
                             notes: 'test notes',
                             subtenant_id: 'user_subtenant')
    end

    describe '#initialize' do
      it 'sets the appropriate instance vars' do
        expect(request.catalog_id).to eq 'catalog-12345'
        expect(request.cpus).to eq 2
        expect(request.memory).to eq 1024
        expect(request.lease_days).to eq 15
        expect(request.requested_for).to eq 'tester@corp.local'
        expect(request.notes).to eq 'test notes'
        expect(request.subtenant_id).to eq 'user_subtenant'
      end
    end

    describe '#validate_params!' do
      context 'when all required params are provided' do
        it 'does not raise an exception' do
          expect { request.validate_params! }.to_not raise_error
        end
      end

      context 'when a required parameter is not provided' do
        it 'raises an exception' do
          request.requested_for = nil
          expect { request.validate_params! }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#fetch_catalog_item' do
      context 'when the catalog item exists' do
        payload = {
          'organization' => {
            'tenantRef' => 'mytenant',
            'subtenantRef' => 'mysubtenant'
          },
          'providerBinding' => { 'bindingId' => 'blueprint-54321' }
        }

        let(:response) { double('response', code: 200, body: payload.to_json) }

        it 'calls http_get against the catalog_service' do
          expect(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_return(response)
          request.fetch_catalog_item
        end

        it 'populated the catalog_details hash properly' do
          allow(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_return(response)
          request.fetch_catalog_item

          expect(request.catalog_detail(:tenant_id)).to eq 'mytenant'
          expect(request.catalog_detail(:subtenant_id)).to eq 'mysubtenant'
          expect(request.catalog_detail(:blueprint_id)).to eq 'blueprint-54321'
        end
      end

      context 'when the catalog item does not exist' do
        it 'raises an exception' do
          allow(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_raise(Vra::Exception::HTTPNotFound)
          expect { request.fetch_catalog_item }.to raise_error(Vra::Exception::NotFound)
        end
      end
    end

    describe '#request_payload' do
      it 'gets the tenant ID and blueprint ID from catalog details' do
        allow(request).to receive(:fetch_catalog_item)
        expect(request).to receive(:catalog_detail).at_least(:once).with(:tenant_id)
        expect(request).to receive(:catalog_detail).at_least(:once).with(:blueprint_id)
        request.request_payload
      end

      it 'properly handles additional parameters' do
        request.set_parameter('param1', 'string', 'my string')
        request.set_parameter('param2', 'integer', '2468')
        allow(request).to receive(:fetch_catalog_item)

        payload = request.request_payload
        param1 = payload['requestData']['entries'].find { |x| x['key'] == 'param1' }
        param2 = payload['requestData']['entries'].find { |x| x['key'] == 'param2' }

        expect(param1).to be_a(Hash)
        expect(param2).to be_a(Hash)
        expect(param1['value']['value']).to eq 'my string'
        expect(param2['value']['value']).to eq 2468
      end
    end

    describe '#submit' do
      before do
        allow(request).to receive(:request_payload).and_return({})
        response = double('response', code: 200, headers: { location: '/requests/request-12345' })
        allow(client).to receive(:http_post).with('/catalog-service/api/consumer/requests', '{}').and_return(response)
      end

      it 'calls http_post' do
        expect(client).to receive(:http_post).with('/catalog-service/api/consumer/requests', '{}')

        request.submit
      end

      it 'returns a Vra::Request object' do
        expect(request.submit).to be_an_instance_of(Vra::Request)
      end
    end
  end
end
