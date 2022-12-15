# frozen_string_literal: true
#
# Author:: Ashique Saidalavi (<ashique.saidalavi@progress.com>)
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

describe ::Vra::Deployment do
  let(:client) do
    Vra::Client.new(
      username: "user@corp.local",
      password: "password",
      domain: "domain",
      base_url: "https://vra.corp.local"
    )
  end

  let(:sample_data) do
    JSON.parse(File.read("spec/fixtures/resource/sample_deployment.json"))
  end

  let(:deployment) do
    described_class.new(client, data: sample_data)
  end

  before(:each) do
    allow(client).to receive(:authorized?).and_return(true)
  end

  describe "#initialize" do
    let(:deployment) do
      described_class.allocate
    end

    before(:each) do
      allow(client).to receive(:get_parsed).and_return(sample_data)
    end

    it "should validate the attributes" do
      expect(deployment).to receive(:validate!)

      deployment.send(:initialize, client, id: "dep-123")
    end

    it "should fetch data when id is passed" do
      deployment.send(:initialize, client, id: "dep-123")

      expect(deployment.send(:data)).not_to be_nil
    end

    it "should set id when data is passed" do
      deployment.send(:initialize, client, data: sample_data)

      expect(deployment.id).to eq("dep-123")
    end
  end

  describe "#refresh" do
    it "should refresh the data correctly" do
      expect(client).to receive(:get_parsed).and_return(sample_data)

      deployment.refresh
    end

    it "should raise an exception if record not found" do
      expect(client).to receive(:get_parsed).and_raise(Vra::Exception::HTTPNotFound)

      expect { deployment.refresh }.to raise_error(Vra::Exception::NotFound)
    end
  end

  describe "#attributes" do
    it "should have the correct attributes" do
      expect(deployment.name).to eq("win-DCI")
      expect(deployment.description).to eq("win-dci deployment")
      expect(deployment.org_id).to eq("origin-123")
      expect(deployment.blueprint_id).to eq("blueprint-123")
      expect(deployment.owner).to eq("administrator")
      expect(deployment.status).to eq("CREATE_SUCCESSFUL")
      expect(deployment.successful?).to be_truthy
      expect(deployment.completed?).to be_truthy
      expect(deployment.failed?).to be_falsey
    end
  end

  describe "#requests" do
    let(:request_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_dep_request.json"))
    end

    it "should call the api to fetch the requests" do
      expect(client)
        .to receive(:get_parsed)
        .with("/deployment/api/deployments/dep-123/requests")
        .and_return({ "content" => [request_data] })

      deployment.requests
    end

    it "should return the Vra::Request object" do
      stub_request(:get, client.full_url("/deployment/api/deployments/dep-123/requests"))
        .to_return(status: 200, body: { "content" => [request_data] }.to_json, headers: {})

      res = deployment.requests.first
      expect(res).to be_an_instance_of(Vra::Request)
    end

    it "should return the correct request data" do
      allow(client)
        .to receive(:get_parsed)
        .with("/deployment/api/deployments/dep-123/requests")
        .and_return({ "content" => [request_data] })

      res = deployment.requests.first
      expect(res.status).to eq("SUCCESSFUL")
      expect(res.name).to eq("Create")
      expect(res.requested_by).to eq("admin")
    end
  end

  describe "#resources" do
    let(:resource_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_dep_resource.json"))
    end

    it "should call the api to fetch the resources" do
      expect(client)
        .to receive(:get_parsed)
        .with("/deployment/api/deployments/dep-123/resources")
        .and_return({ "content" => [resource_data] })

      res = deployment.resources.first
      expect(res).to be_an_instance_of(Vra::Resource)
    end

    it "should have the correct resource data" do
      expect(client).to receive(:get_parsed).and_return({ "content" => [resource_data] })

      res = deployment.resources.first
      expect(res.name).to eq("Cloud_vSphere_Machine_1")
      expect(res.status).to eq("SUCCESS")
      expect(res.vm?).to be_truthy
      expect(res.owner_names).to eq("admin")
    end
  end

  describe "#actions" do
    let(:actions_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_dep_actions.json"))
    end

    def action_req(action)
      {
        actionId: "Deployment.#{camelize(action)}",
        inputs: {},
        reason: "Testing the #{action}",
      }.to_json
    end

    def action_response(action)
      {
        "id" => "req-123",
        "name" => camelize(action),
        "requestedBy" => "admin",
        "blueprintId" => "blueprint-123",
        "inputs" => {
          "flag" => "false",
          "count" => "1",
          "hardware-config" => "Medium",
        },
        "status" => "SUCCESSFUL",
      }.to_json
    end

    def camelize(action_name)
      action_name.split("_").map(&:capitalize).join
    end

    it "should call the api to fetch the actions" do
      expect(client)
        .to receive(:get_parsed)
        .with("/deployment/api/deployments/dep-123/actions")
        .and_return(actions_data)

      actions = deployment.actions
      expect(actions).to be_an_instance_of(Array)
    end

    it "should return the correct actions" do
      allow(client).to receive(:get_parsed).and_return(actions_data)

      action_names = deployment.actions.map { |a| a["name"] }
      expect(action_names).to eq(%w{ChangeLease ChangeOwner Delete EditTags PowerOff PowerOn Update})
    end

    {
      destroy: "delete",
      power_on: "power_on",
      power_off: "power_off",
    }.each do |method, action|
      it "should perform the action: #{action} correctly" do
        allow(client).to receive(:get_parsed).and_return(actions_data)
        stub_request(:post, client.full_url("/deployment/api/deployments/dep-123/requests"))
          .with(body: action_req(action))
          .to_return(status: 200, body: action_response(action), headers: {})

        action_request = deployment.send(method, "Testing the #{action}")
        expect(action_request).to be_an_instance_of(Vra::Request)
        expect(action_request.name).to eq(camelize(action))
      end
    end
  end
end
