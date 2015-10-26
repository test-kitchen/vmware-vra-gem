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
require 'ffi_yajl'

shared_examples_for 'a resource action' do |action_method, action_name|
  context 'when the action is available' do
    it 'calls gets the action ID and submits the request' do
      expect(resource).to receive(:action_id_by_name).with(action_name).and_return('action-123')
      expect(resource).to receive(:submit_action_request).with('action-123')
      resource.send(action_method)
    end
  end

  context 'when the action is not available' do
    it 'raises an exception' do
      expect(resource).to receive(:action_id_by_name).with(action_name).and_return nil
      expect { resource.send(action_method) }.to raise_error(Vra::Exception::NotFound)
    end
  end
end

describe Vra::Resource do
  let(:client) do
    Vra::Client.new(username: 'user@corp.local',
                    password: 'password',
                    tenant: 'tenant',
                    base_url: 'https://vra.corp.local')
  end

  let(:resource_id) { '31a7badc-6562-458d-84f3-ec58d74a6953' }
  let(:vm_payload) do
    FFI_Yajl::Parser.parse(File.read(File.join(File.dirname(__FILE__),
                                               'fixtures',
                                               'resource',
                                               'vm_resource.json')))
  end

  let(:vm_payload_no_ops) do
    FFI_Yajl::Parser.parse(File.read(File.join(File.dirname(__FILE__),
                                               'fixtures',
                                               'resource',
                                               'vm_resource_no_operations.json')))
  end

  let(:non_vm_payload) do
    FFI_Yajl::Parser.parse(File.read(File.join(File.dirname(__FILE__),
                                               'fixtures',
                                               'resource',
                                               'non_vm_resource.json')))
  end

  describe '#initialize' do
    it 'raises an error if no ID or resource data have been provided' do
      expect { Vra::Resource.new }.to raise_error(ArgumentError)
    end

    it 'raises an error if an ID and resource data have both been provided' do
      expect { Vra::Resource.new(id: 123, data: 'foo') }.to raise_error(ArgumentError)
    end

    context 'when an ID is provided' do
      it 'calls fetch_resource_data' do
        resource = Vra::Resource.allocate
        expect(resource).to receive(:fetch_resource_data)
        resource.send(:initialize, client, id: resource_id)
      end
    end

    context 'when resource data is provided' do
      it 'populates the ID correctly' do
        resource = Vra::Resource.new(client, data: vm_payload)
        expect(resource.id).to eq resource_id
      end
    end
  end

  describe '#fetch_resource_data' do
    it 'calls http_get! against the resources API endpoint' do
      expect(client).to receive(:http_get!)
        .with("/catalog-service/api/consumer/resources/#{resource_id}")
        .and_return('')

      Vra::Resource.new(client, id: resource_id)
    end
  end

  context 'when a valid VM resource instance has been created' do
    let(:resource) { Vra::Resource.new(client, data: vm_payload) }

    describe '#name' do
      it 'returns the correct name' do
        expect(resource.name).to eq 'hol-dev-11'
      end
    end

    describe '#description' do
      it 'returns the correct description' do
        expect(resource.description).to eq 'test-description'
      end
    end

    describe '#status' do
      it 'returns the correct status' do
        expect(resource.status).to eq 'ACTIVE'
      end
    end

    describe '#vm?' do
      it 'returns true for the VM resource we created' do
        expect(resource.vm?).to be true
      end
    end

    describe '#tenant_id' do
      it 'returns the correct tenant ID' do
        expect(resource.tenant_id).to eq 'vsphere.local'
      end
    end

    describe '#tenant_name' do
      it 'returns the correct tenant name' do
        expect(resource.tenant_name).to eq 'vsphere.local'
      end
    end

    describe '#subtenant_id' do
      it 'returns the correct subtenant ID' do
        expect(resource.subtenant_id).to eq '5327ddd3-1a4e-4663-9e9d-63db86ffc8af'
      end
    end

    describe '#subtenant_name' do
      it 'returns the correct subtenant name' do
        expect(resource.subtenant_name).to eq 'Rainpole Developers'
      end
    end

    describe '#owner_ids' do
      it 'returns the correct owner IDs' do
        expect(resource.owner_ids).to eq %w(user1@corp.local user2@corp.local)
      end
    end

    describe '#owner_names' do
      it 'returns the correct owner names' do
        expect(resource.owner_names).to eq [ 'Joe User', 'Jane User' ]
      end
    end

    describe '#machine_status' do
      context 'when no MachineStatus exists' do
        let(:resource_data) { { 'resourceData' => { 'entries' => [] } } }

        it 'raises an exception' do
          allow(resource).to receive(:resource_data).and_return(resource_data)
          expect { resource.machine_status }.to raise_error(RuntimeError)
        end
      end

      context 'when MachineStatus Exists' do
        let(:resource_data) do
          {
            'resourceData' => {
              'entries' => [
                {
                  'key' => 'MachineStatus',
                  'value' => { 'type' => 'string', 'value' => 'Off' }
                }
              ]
            }
          }
        end

        it 'returns the correct status value' do
          allow(resource).to receive(:resource_data).and_return(resource_data)
          expect(resource.machine_status).to eq('Off')
        end
      end
    end

    describe '#machine_on?' do
      it 'returns true if the machine_status is On' do
        allow(resource).to receive(:machine_status).and_return('On')
        expect(resource.machine_on?).to eq(true)
      end

      it 'returns true if the machine_status is TurningOff' do
        allow(resource).to receive(:machine_status).and_return('TurningOff')
        expect(resource.machine_on?).to eq(true)
      end

      it 'returns true if the machine_status is ShuttingDown' do
        allow(resource).to receive(:machine_status).and_return('ShuttingDown')
        expect(resource.machine_on?).to eq(true)
      end

      it 'returns true if the machine_status is On' do
        allow(resource).to receive(:machine_status).and_return('On')
        expect(resource.machine_on?).to eq(true)
      end

      it 'returns false if the machine_status is not On' do
        allow(resource).to receive(:machine_status).and_return('Off')
        expect(resource.machine_on?).to eq(false)
      end
    end

    describe '#machine_off?' do
      it 'returns true if the machine_status is Off' do
        allow(resource).to receive(:machine_status).and_return('Off')
        expect(resource.machine_off?).to eq(true)
      end

      it 'returns false if the machine_status is not Off' do
        allow(resource).to receive(:machine_status).and_return('On')
        expect(resource.machine_off?).to eq(false)
      end
    end

    describe '#network_interfaces' do
      it 'returns an array of 2 elements' do
        expect(resource.network_interfaces.size).to be 2
      end

      it 'contains the correct data' do
        nic1, nic2 = resource.network_interfaces

        expect(nic1['NETWORK_NAME']).to eq 'VM Network'
        expect(nic1['NETWORK_ADDRESS']).to eq '192.168.110.200'
        expect(nic1['NETWORK_MAC_ADDRESS']).to eq '00:50:56:ae:95:3c'

        expect(nic2['NETWORK_NAME']).to eq 'Management Network'
        expect(nic2['NETWORK_ADDRESS']).to eq '192.168.220.200'
        expect(nic2['NETWORK_MAC_ADDRESS']).to eq '00:50:56:ae:95:3d'
      end
    end

    describe '#ip_addresses' do
      it 'returns the correct IP addresses' do
        expect(resource.ip_addresses).to eq [ '192.168.110.200', '192.168.220.200' ]
      end

      it 'returns nil if there are no network interfaces' do
        allow(resource).to receive(:network_interfaces).and_return nil
        expect(resource.ip_addresses).to be_nil
      end
    end

    describe '#actions' do
      it 'does not call #fetch_resource_data' do
        expect(resource).not_to receive(:fetch_resource_data)
        resource.actions
      end
    end

    describe '#action_id_by_name' do
      it 'returns the correct action ID for the destroy action' do
        expect(resource.action_id_by_name('Destroy')).to eq 'ace8ba42-e724-48d8-9614-9b3a62b5a464'
      end

      it 'returns nil if there are no resource operations' do
        allow(resource).to receive(:actions).and_return nil
        expect(resource.action_id_by_name('Destroy')).to be_nil
      end

      it 'returns nil if there are actions, but none with the right name' do
        allow(resource).to receive(:actions).and_return([ { 'name' => 'some action' }, { 'name' => 'another action' } ])
        expect(resource.action_id_by_name('Destroy')).to be_nil
      end
    end

    describe '#destroy' do
      it_behaves_like 'a resource action', :destroy, 'Destroy'
    end

    describe '#shutdown' do
      it_behaves_like 'a resource action', :shutdown, 'Shutdown'
    end

    describe '#poweroff' do
      it_behaves_like 'a resource action', :poweroff, 'Power Off'
    end

    describe '#poweron' do
      it_behaves_like 'a resource action', :poweron, 'Power On'
    end

    describe '#submit_action_request' do
      before do
        allow(resource).to receive(:action_request_payload).and_return({})
        response = double('response', code: 200, headers: { location: '/requests/request-12345' })
        allow(client).to receive(:http_post).with('/catalog-service/api/consumer/requests', '{}').and_return(response)
      end

      it 'calls http_post' do
        expect(client).to receive(:http_post).with('/catalog-service/api/consumer/requests', '{}')

        resource.submit_action_request('action-123')
      end

      it 'returns a Vra::Request object' do
        expect(resource.submit_action_request('action-123')).to be_an_instance_of(Vra::Request)
      end
    end
  end

  context 'when a valid VM resource instance with no operations is created' do
    let(:resource) { Vra::Resource.new(client, data: vm_payload_no_ops) }

    describe '#actions' do
      it 'calls #fetch_resource_data' do
        expect(resource).to receive(:fetch_resource_data)
        resource.actions
      end
    end
  end

  context 'when a valid non-VM resource instance has been created' do
    let(:resource) { Vra::Resource.new(client, data: non_vm_payload) }

    it 'returns nil for network_interfaces and ip_addresses' do
      expect(resource.network_interfaces).to be_nil
      expect(resource.ip_addresses).to be_nil
    end
  end
end
