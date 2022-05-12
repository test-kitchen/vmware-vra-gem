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

require "spec_helper"
require "ffi_yajl"

describe Vra::Resource do
  let(:client) do
    Vra::Client.new(
      username: "user@corp.local",
      password: "password",
      tenant: "tenant",
      base_url: "https://vra.corp.local"
    )
  end

  let(:resource_id) { "res-123" }
  let(:deployment_id) { "dep-123" }

  let(:vm_payload) do
    JSON.parse(File.read("spec/fixtures/resource/sample_dep_resource.json"))
  end

  describe "#initialize" do
    it "raises an error if no ID or resource data have been provided" do
      expect { Vra::Resource.new(client, deployment_id) }.to raise_error(ArgumentError)
    end

    it "raises an error if an ID and resource data have both been provided" do
      expect { Vra::Resource.new(client, deployment_id, id: 123, data: "foo") }.to raise_error(ArgumentError)
    end

    context "when an ID is provided" do
      it "calls fetch_resource_data" do
        resource = Vra::Resource.allocate
        expect(resource).to receive(:fetch_resource_data)
        resource.send(:initialize, client, deployment_id, id: resource_id)
      end
    end

    context "when resource data is provided" do
      it "populates the ID correctly" do
        resource = Vra::Resource.new(client, deployment_id, data: vm_payload)
        expect(resource.id).to eq resource_id
      end
    end
  end

  describe "#fetch_resource_data" do
    it "calls get_parsed against the resources API endpoint" do
      expect(client).to receive(:get_parsed)
        .with("/deployment/api/deployments/#{deployment_id}/resources/#{resource_id}")
        .and_return({})

      Vra::Resource.new(client, deployment_id, id: resource_id)
    end

    it "should raise an exception if the resource not found" do
      allow(client).to receive(:get_parsed).and_raise(Vra::Exception::HTTPNotFound)

      expect { Vra::Resource.new(client, deployment_id, id: resource_id) }
        .to raise_error(Vra::Exception::NotFound)
        .with_message("resource ID #{resource_id} does not exist")
    end
  end

  context "when a valid VM resource instance has been created" do
    let(:resource) { Vra::Resource.new(client, deployment_id, data: vm_payload) }

    describe "#name" do
      it "returns the correct name" do
        expect(resource.name).to eq "Cloud_vSphere_Machine_1"
      end
    end

    describe "#status" do
      it "returns the correct status" do
        expect(resource.status).to eq "SUCCESS"
      end
    end

    describe "#vm?" do
      context "when the resource type is Cloud.vSphere.Machine" do
        let(:resource_data) { { "type" => "Cloud.vSphere.Machine" } }
        it "returns true" do
          allow(resource).to receive(:resource_data).and_return(resource_data)
          expect(resource.vm?).to eq(true)
        end
      end

      context "when the resource type is Cloud.Machine" do
        let(:resource_data) { { "type" => "Cloud.Machine" } }
        it "returns true" do
          allow(resource).to receive(:resource_data).and_return(resource_data)
          expect(resource.vm?).to eq(true)
        end
      end

      context "when the resource type is an unknown type" do
        let(:resource_data) { { "type" => "Infrastructure.Unknown" } }
        it "returns false" do
          allow(resource).to receive(:resource_data).and_return(resource_data)
          expect(resource.vm?).to eq(false)
        end
      end
    end

    describe "#project" do
      it "returns the correct project ID" do
        expect(resource.project_id).to eq "pro-123"
      end
    end

    describe "#owner_names" do
      it "returns the correct owner names" do
        expect(resource.owner_names).to eq "admin"
      end
    end

    describe "#network_interfaces" do
      it "returns an array of 2 elements" do
        expect(resource.network_interfaces.size).to be 2
      end

      it "contains the correct data" do
        nic1, nic2 = resource.network_interfaces

        expect(nic1["NETWORK_NAME"]).to eq "VM Network"
        expect(nic1["NETWORK_ADDRESS"]).to eq "192.168.110.200"
        expect(nic1["NETWORK_MAC_ADDRESS"]).to eq "00:50:56:ae:95:3c"

        expect(nic2["NETWORK_NAME"]).to eq "Management Network"
        expect(nic2["NETWORK_ADDRESS"]).to eq "192.168.220.200"
        expect(nic2["NETWORK_MAC_ADDRESS"]).to eq "00:50:56:ae:95:3d"
      end
    end

    describe "#ip_addresses" do
      it "should have the correct ip address" do
        expect(resource.ip_address).to eq "10.30.236.64"
      end
    end
  end
end
