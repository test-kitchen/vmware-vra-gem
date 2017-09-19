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

require "spec_helper"

describe Vra::CatalogRequest do
  before(:each) do
    catalog_item = double("catalog_item")
    allow(catalog_item).to receive(:blueprint_id).and_return("catalog_blueprint")
    allow(catalog_item).to receive(:tenant_id).and_return("catalog_tenant")
    allow(catalog_item).to receive(:subtenant_id).and_return("catalog_subtenant")
    allow(Vra::CatalogItem).to receive(:new).and_return(catalog_item)
  end

  let(:client) do
    Vra::Client.new(username: "user@corp.local",
                    password: "password",
                    tenant: "tenant",
                    base_url: "https://vra.corp.local")
  end

  let(:catalog_item_payload) do
    {
        "@type" => "CatalogItem",
        "id" => "9e98042e-5443-4082-afd5-ab5a32939bbc",
        "version" => 2,
        "name" => "CentOS 6.6",
        "description" => "Blueprint for deploying a CentOS Linux development server",
        "status" => "PUBLISHED",
        "statusName" => "Published",
        "organization" => {
            "tenantRef" => "vsphere.local",
            "tenantLabel" => "vsphere.local",
            "subtenantRef" => "962ab3f9-858c-4483-a49f-fa97392c314b",
            "subtenantLabel" => "catalog_subtenant",
        },
        "providerBinding" => {
            "bindingId" => "33af5413-4f20-4b3b-8268-32edad434dfb",
            "providerRef" => {
                "id" => "c3b2bc30-47b0-454f-b57d-df02a7356fe6",
                "label" => "iaas-service",
            },
        },
        "requestedFor" => "me@me.com",
        "data" => {
            "_leaseDays" => "2",
            "my_blueprint" => {
            "componentTypeId" => "com.vmware.csp.component.cafe.composition",
            "componentId" => nil,
            "classId" => "Blueprint.Component.Declaration",
            "typeFilter" => "",
            "data" => {
                "cpu" => "2",
                "memory" => "4096",

            },
          },
        },
    }
  end

  let(:request_template_response) do
    double("response", code: 200, body: catalog_item_payload.to_json)
  end

  context "when no subtenant ID is provided" do
    let(:request) do
      client.catalog.request("catalog-12345",
                             cpus: 2,
                             memory: 1024,
                             lease_days: 15,
                             requested_for: "tester@corp.local",
                             notes: "test notes")
    end

    it "uses the subtenant ID from the catalog item" do
      expect(request.subtenant_id).to eq "catalog_subtenant"
    end
  end

  context "when subtenant is provided, and all shared tests" do
    let(:request) do
      client.catalog.request("catalog-12345",
                             cpus: 2,
                             memory: 1024,
                             lease_days: 15,
                             requested_for: "tester@corp.local",
                             notes: "test notes",
                             subtenant_id: "user_subtenant")
    end

    describe "#initialize" do
      it "sets the appropriate instance vars" do
        expect(request.catalog_id).to eq "catalog-12345"
        expect(request.cpus).to eq 2
        expect(request.memory).to eq 1024
        expect(request.lease_days).to eq 15
        expect(request.requested_for).to eq "tester@corp.local"
        expect(request.notes).to eq "test notes"
        expect(request.subtenant_id).to eq "user_subtenant"
      end
    end

    describe "#validate_params!" do
      context "when all required params are provided" do
        it "does not raise an exception" do
          expect { request.validate_params! }.to_not raise_error
        end
      end

      context "when a required parameter is not provided" do
        it "raises an exception" do
          request.cpus = nil
          expect { request.validate_params! }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#merge_payload" do
      it "properly handles additional parameters" do
        request.set_parameter("param1", "string", "my string")
        request.set_parameter("param2", "integer", "2468")

        template = File.read("spec/fixtures/resource/catalog_request.json")
        payload = JSON.parse(request.merge_payload(template))
        param1 = payload["data"]["param1"]
        param2 = payload["data"]["param2"]

        expect(param1).to be_a(String)
        expect(param2).to be_a(Integer)
        expect(param1).to eq "my string"
        expect(param2).to eq 2468
      end

      it "properly handles additional nested parameters" do
        request.set_parameter("BP1~param1", "string", "my string")
        request.set_parameter("BP1~BP2~param2", "integer", 2468)

        template = File.read("spec/fixtures/resource/catalog_request.json")
        payload = JSON.parse(request.merge_payload(template))
        param1 = payload["data"]["BP1"]["data"]["param1"]
        param2 = payload["data"]["BP1"]["data"]["BP2"]["data"]["param2"]

        expect(param1).to be_a(String)
        expect(param2).to be_a(Integer)
        expect(param1).to eq "my string"
        expect(param2).to eq 2468
      end

      it "properly handles nested parameters" do
        parameters = {
          "BP1" => {
              "param1" => {
                type: "string",
                value: "my string",
              },
              "BP2" => {
                  "param2" => {
                    type: "integer",
                    value: 2468,
                  },
                },
            },
        }

        parameters.each do |k, v|
          request.set_parameters(k, v)
        end

        template = File.read("spec/fixtures/resource/catalog_request.json")
        payload = JSON.parse(request.merge_payload(template))
        param1 = payload["data"]["BP1"]["data"]["param1"]
        param2 = payload["data"]["BP1"]["data"]["BP2"]["data"]["param2"]

        expect(param1).to be_a(String)
        expect(param2).to be_a(Integer)
        expect(param1).to eq "my string"
        expect(param2).to eq 2468
      end
    end

    describe "#submit" do
      let(:response) do
        double("response", code: 200, body: { id: "12345678910" }.to_json)
      end

      before do
        allow(request).to receive(:request_payload).and_return({})
        allow(client).to receive(:authorize!).and_return(true)
        allow(client).to receive(:http_post).with("/catalog-service/api/consumer/requests", "{}").and_return(response)
        allow(client).to receive(:http_get).with("/catalog-service/api/consumer/entitledCatalogItems/catalog-12345/requests/template")
                             .and_return(request_template_response)
      end

      it "calls http_get template" do
        expect(client).to receive(:http_get).with("/catalog-service/api/consumer/entitledCatalogItems/catalog-12345/requests/template")
                              .and_return(request_template_response)
        allow(client).to receive(:http_post).with("/catalog-service/api/consumer/entitledCatalogItems/catalog-12345/requests", request.merged_payload).and_return(response)
        request.submit
      end

      it "calls http_post" do
        expect(client).to receive(:http_post).with("/catalog-service/api/consumer/entitledCatalogItems/catalog-12345/requests", request.merged_payload).and_return(response)
        request.submit
      end

      it "returns Vra::Request" do
        allow(client).to receive(:http_post).with("/catalog-service/api/consumer/entitledCatalogItems/catalog-12345/requests", request.merged_payload).and_return(response)
        expect(request.submit).to be_a(Vra::Request)
      end
    end
  end

  describe "merges payload" do
    let(:request) do
      client.catalog.request("catalog-12345",
                             cpus: 2,
                             memory: 1024,
                             lease_days: 15,
                             requested_for: "tester@corp.local",
                             notes: "test notes")
    end
    before(:each) do
      allow(Vra::CatalogItem).to receive(:dump_template).and_return({ data2: { key2: "value2" } }.merge(catalog_item_payload).to_json)
    end

    it "without catalog template" do
      request.template_payload = { data2: { key1: "value1" } }.merge(catalog_item_payload).to_json
      template = JSON.parse(request.merged_payload)
      expect(template["data2"].keys).to_not include("key2")
    end

    it "with catalog template" do
      request.template_payload = nil
      template = JSON.parse(request.merged_payload)
      expect(template["data2"].keys).to include("key2")
    end
  end

  it "creates request" do
    payload_file = File.join(fixtures_dir, "catalog_request_template.json")
    expect(Vra::CatalogRequest.request_from_payload(client, payload_file)).to be_a(Vra::CatalogRequest)
  end

  it "creates request with correct payload" do
    payload_file = File.join(fixtures_dir, "catalog_request_template.json")
    cr = Vra::CatalogRequest.request_from_payload(client, payload_file)
    data = JSON.parse(cr.merged_payload)
    expect(data["data"]["superduper_key"]).to eq("superduper_value")
  end
end
