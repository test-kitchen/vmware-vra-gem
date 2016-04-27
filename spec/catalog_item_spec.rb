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

describe Vra::CatalogItem do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:catalog_id) { '9e98042e-5443-4082-afd5-ab5a32939bbc' }

  let(:catalog_item_payload) do
    {
      '@type' => 'CatalogItem',
      'id' => '9e98042e-5443-4082-afd5-ab5a32939bbc',
      'version' => 2,
      'name' => 'CentOS 6.6',
      'description' => 'Blueprint for deploying a CentOS Linux development server',
      'status' => 'PUBLISHED',
      'statusName' => 'Published',
      'organization' => {
        'tenantRef' => 'vsphere.local',
        'tenantLabel' => 'vsphere.local',
        'subtenantRef' => '962ab3f9-858c-4483-a49f-fa97392c314b',
        'subtenantLabel' => 'catalog_subtenant'
      },
      'providerBinding' => {
        'bindingId' => '33af5413-4f20-4b3b-8268-32edad434dfb',
        'providerRef' => {
          'id' => 'c3b2bc30-47b0-454f-b57d-df02a7356fe6',
          'label' => 'iaas-service'
        }
      }
    }
  end

  describe '#initialize' do
    it 'raises an error if no ID or catalog item data have been provided' do
      expect { Vra::CatalogItem.new }.to raise_error(ArgumentError)
    end

    it 'raises an error if an ID and catalog item data have both been provided' do
      expect { Vra::CatalogItem.new(id: 123, data: 'foo') }.to raise_error(ArgumentError)
    end

    context 'when an ID is provided' do
      it 'fetches the catalog_item record' do
        catalog_item = Vra::CatalogItem.allocate
        expect(catalog_item).to receive(:fetch_catalog_item)
        catalog_item.send(:initialize, client, id: catalog_id)
      end
    end

    context 'when catalog item data is provided' do
      it 'populates the ID correctly' do
        catalog_item = Vra::CatalogItem.new(client, data: catalog_item_payload)
        expect(catalog_item.id).to eq catalog_id
      end
    end
  end

  describe '#fetch_catalog_item' do
    context 'when the catalog item exists' do
      let(:response) { double('response', code: 200, body: catalog_item_payload.to_json) }

      it 'calls http_get against the catalog_service' do
        expect(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_return(response)
        Vra::CatalogItem.new(client, id: 'catalog-12345')
      end
    end

    context 'when the catalog item does not exist' do
      it 'raises an exception' do
        allow(client).to receive(:http_get).with('/catalog-service/api/consumer/catalogItems/catalog-12345').and_raise(Vra::Exception::HTTPNotFound)
        expect { Vra::CatalogItem.new(client, id: 'catalog-12345') }.to raise_error(Vra::Exception::NotFound)
      end
    end
  end

  describe '#organization' do
    let(:catalog_item) { Vra::CatalogItem.new(client, data: catalog_item_payload) }

    context 'when organization data exists' do
      let(:catalog_item_payload) do
        {
          '@type' => 'CatalogItem',
          'id' => '9e98042e-5443-4082-afd5-ab5a32939bbc',
          'organization' => {
            'tenantRef' => 'vsphere.local',
            'tenantLabel' => 'vsphere.local',
            'subtenantRef' => '962ab3f9-858c-4483-a49f-fa97392c314b',
            'subtenantLabel' => 'catalog_subtenant'
          }
        }
      end

      it 'returns the correct organization data' do
        expect(catalog_item.organization['tenantRef']).to eq('vsphere.local')
      end
    end

    context 'when organization data does not exist' do
      let(:catalog_item_payload) do
        {
          '@type' => 'CatalogItem',
          'id' => '9e98042e-5443-4082-afd5-ab5a32939bbc'
        }
      end

      it 'returns an empty hash' do
        expect(catalog_item.organization).to eq({})
      end

      it 'returns nil for any organization keys' do
        expect(catalog_item.organization['tenantRef']).to eq(nil)
      end
    end
  end
end
