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

describe Vra::Requests do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:requests) { Vra::Requests.new(client) }

  describe '#all_resources' do
    it 'calls the requests API endpoint' do
      expect(client).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/requests')
        .and_return([])

      requests.all_requests
    end

    it 'returns an array of request objects' do
      allow(client).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/requests')
        .and_return([ { 'id' => '1' }, { 'id' => '2' } ])

      items = requests.all_requests

      expect(items[0]).to be_an_instance_of(Vra::Request)
      expect(items[1]).to be_an_instance_of(Vra::Request)
    end
  end

  describe '#by_id' do
    it 'returns a request object' do
      expect(Vra::Request).to receive(:new).with(client, '12345')

      requests.by_id('12345')
    end
  end
end
