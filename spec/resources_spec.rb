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

describe Vra::Resources do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:resources) { Vra::Resources.new(client) }

  describe '#all_resources' do
    it 'calls the resources API endpoint' do
      expect(client).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/resources')
        .and_return([])

      resources.all_resources
    end

    it 'returns an array of resource objects' do
      allow(client).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/resources')
        .and_return([ { 'id' => '1' }, { 'id' => '2' } ])

      items = resources.all_resources

      expect(items[0]).to be_an_instance_of(Vra::Resource)
      expect(items[1]).to be_an_instance_of(Vra::Resource)
    end
  end

  describe '#by_id' do
    it 'returns a resource object' do
      expect(Vra::Resource).to receive(:new).with(client, id: '12345')

      resources.by_id('12345')
    end
  end
end
