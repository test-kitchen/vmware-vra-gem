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

describe Vra::Catalog do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:catalog_item) do
    {
      '@type' => 'CatalogItem',
      'id' => 'a9cd6148-6e0b-4a80-ac47-f5255c52b43d',
      'version' => 2,
      'name' => 'CentOS 6.6',
      'description' => 'Blueprint for deploying a CentOS Linux development server',
      'status' => 'PUBLISHED',
      'statusName' => 'Published',
      'organization' => {
        'tenantRef' => 'vsphere.local',
        'tenantLabel' => 'vsphere.local',
        'subtenantRef' => nil,
        'subtenantLabel' => nil
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

  let(:entitled_catalog_item) do
    {
      '@type' => 'ConsumerEntitledCatalogItem',
      'catalogItem' => {
        'id' => 'd29efd6b-3cd6-4f8d-b1d8-da4ddd4e52b1',
        'version' => 2,
        'name' => 'WindowsServer2012',
        'description' => 'Windows Server 2012 with the latest updates and patches.',
        'status' => 'PUBLISHED',
        'statusName' => 'Published',
        'organization' => {
          'tenantRef' => 'vsphere.local',
          'tenantLabel' => 'vsphere.local',
          'subtenantRef' => nil,
          'subtenantLabel' => nil
        },
        'providerBinding' => {
          'bindingId' => '59fd02a1-acca-4918-9d3d-2298d310caef',
          'providerRef' => {
            'id' => 'c3b2bc30-47b0-454f-b57d-df02a7356fe6',
            'label' => 'iaas-service'
          }
        }
      }
    }
  end

  describe '#all_items' do
    it 'calls the catalogItems endpoint' do
      expect(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/catalogItems')
        .and_return([ catalog_item ])

      client.catalog.all_items
    end

    it 'returns a Vra::CatalogItem object' do
      allow(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/catalogItems')
        .and_return([ catalog_item ])

      items = client.catalog.all_items

      expect(items.first).to be_an_instance_of(Vra::CatalogItem)
    end
  end

  describe '#entitled_items' do
    it 'calls the entitledCatalogItems endpoint' do
      expect(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/entitledCatalogItems')
        .and_return([ entitled_catalog_item ])

      client.catalog.entitled_items
    end

    it 'returns a Vra::CatalogItem object' do
      allow(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/entitledCatalogItems')
        .and_return([ entitled_catalog_item ])

      items = client.catalog.entitled_items

      expect(items.first).to be_an_instance_of(Vra::CatalogItem)
    end
  end

  describe '#request' do
    it 'returns a new Vra::CatalogRequest object' do
      allow(Vra::CatalogItem).to receive(:new)
      request = client.catalog.request('blueprint-1', cpus: 2)
      expect(request).to be_an_instance_of(Vra::CatalogRequest)
    end
  end
end
