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

  describe '#all_items' do
    it 'calls the catalogItems endpoint' do
      expect(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/catalogItems')

      client.catalog.all_items
    end
  end

  describe '#entitled_items' do
    it 'calls the entitledCatalogItems endpoint' do
      expect(client).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/entitledCatalogItems')

      client.catalog.entitled_items
    end
  end

  describe '#request' do
    it 'returns a new Vra::CatalogRequest object' do
      request = client.catalog.request('blueprint-1', cpus: 2)
      expect(request).to be_an_instance_of(Vra::CatalogRequest)
    end
  end
end
