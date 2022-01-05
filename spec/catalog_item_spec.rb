# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2022 Chef Software, Inc.
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
    Vra::Client.new(
      username: 'user@corp.local',
      password: 'password',
      tenant: 'tenant',
      base_url: 'https://vra.corp.local'
    )
  end

  let(:catalog_id) { '123456' }

  let(:catalog_item_payload) do
    JSON.parse(File.read('spec/fixtures/resource/sample_catalog_item.json'))
  end

  let(:other_catalog_item_payload) do
    JSON.parse(File.read('spec/fixtures/resource/sample_catalog_item_2.json'))
  end

  describe '#initialize' do
    it 'raises an error if no ID or catalog item data have been provided' do
      expect { Vra::CatalogItem.new(client) }.to raise_error(ArgumentError)
    end

    it 'raises an error if an ID and catalog item data have both been provided' do
      expect { Vra::CatalogItem.new(client, id: 123, data: 'foo') }.to raise_error(ArgumentError)
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
        expect(client).to receive(:http_get).with('/catalog/api/admin/items/catalog-12345').and_return(response)
        Vra::CatalogItem.new(client, id: 'catalog-12345')
      end
    end

    context 'when the catalog item does not exist' do
      it 'raises an exception' do
        allow(client)
          .to receive(:http_get)
          .with('/catalog/api/admin/items/catalog-12345')
          .and_raise(Vra::Exception::HTTPNotFound)

        expect { Vra::CatalogItem.new(client, id: 'catalog-12345') }
          .to raise_error(Vra::Exception::NotFound)
          .with_message('catalog ID catalog-12345 does not exist')
      end
    end
  end

  describe '#entitle!' do
    it 'should entitle the catalog item' do
      allow(client).to receive(:authorized?).and_return(true)
      stub_request(:get, client.full_url('/catalog/api/admin/items/123456'))
        .to_return(status: 200, body: catalog_item_payload.to_json, headers: {})

      response = double('response', body: '{"message": "success"}', success?: true)
      allow(client).to receive(:http_post).and_return(response)

      entitle_response = described_class.entitle!(client, '123456')
      expect(entitle_response).not_to be_nil
    end
  end

  describe '#attributes' do
    it 'should have the correct attributes' do
      allow(client).to receive(:authorized?).and_return(true)
      stub_request(:get, client.full_url('/catalog/api/admin/sources/source-123456'))
        .to_return(
          status: 200,
          body: File.read('spec/fixtures/resource/sample_catalog_source.json'),
          headers: {}
        )
      catalog_item = described_class.new(client, data: catalog_item_payload)

      expect(catalog_item.name).to eq('centos')
      expect(catalog_item.description).to eq('Centos Cat')
      expect(catalog_item.source_id).to eq('source-123456')
      expect(catalog_item.source_name).to eq('Source 123')
      expect(catalog_item.icon_id).to eq('1495b8d9')
      expect(catalog_item.source).to be_a(Vra::CatalogSource)
      expect(catalog_item.type).to be_a(Vra::CatalogType)
    end
  end
end
