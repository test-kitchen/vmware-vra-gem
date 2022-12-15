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

describe Vra::CatalogSource do
  let(:client) do
    Vra::Client.new(
      username: "user@corp.local",
      password: "password",
      domain: "domain",
      base_url: "https://vra.corp.local"
    )
  end

  let(:sample_data) do
    JSON.parse(File.read("spec/fixtures/resource/sample_catalog_source.json"))
  end

  describe "#initialize" do
    let(:source) do
      described_class.allocate
    end

    before(:each) do
      allow(client).to receive(:get_parsed).and_return(sample_data)
    end

    it "should validate and fetch data" do
      expect(source).to receive(:validate!)
      expect(source).to receive(:fetch_data)

      source.send(:initialize, client, id: "123456")
    end

    it "should fetch data when id is passed" do
      source.send(:initialize, client, id: "123456")

      expect(source.send(:data)).not_to be_nil
    end

    it "should set id when data is passed" do
      source.send(:initialize, client, data: sample_data)

      expect(source.id).to eq("123456")
    end
  end

  describe "#validate" do
    let(:source) do
      described_class.allocate
    end

    it "should raise exception when neither id nor data passed" do
      expect { source.send(:initialize, client) }.to raise_error(ArgumentError)
    end

    it "should raise exception when both id and data is passed" do
      params = [client, { id: "com.vmw.vra.workflow", data: sample_data }]
      expect { source.send(:initialize, *params) }.to raise_error(ArgumentError)
    end
  end

  describe "#fetch_data" do
    let(:source) do
      described_class.allocate
    end

    it "should fetch the data correctly" do
      allow(client).to receive(:get_parsed).and_return(sample_data)
      source.send(:initialize, client, id: "123456")

      data = source.send(:data)
      expect(data).to be(sample_data)
      expect(source.id).to eq(data["id"])
      expect(data["name"]).to eq("Devops")
    end

    it "should raise when catalog with id not found" do
      allow(client).to receive(:get_parsed).and_raise(Vra::Exception::HTTPNotFound)

      expect { source.send(:initialize, client, id: sample_data["id"]) }
        .to raise_error(Vra::Exception::NotFound)
        .with_message("catalog source ID #{sample_data["id"]} does not exist")
    end
  end

  describe "attributes" do
    let(:sample_type_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_catalog_type.json"))
    end

    it "should have the correct attributes" do
      allow(client).to receive(:get_parsed).twice.and_return(sample_data, sample_type_data)

      source = described_class.new(client, id: sample_data["id"])
      expect(source.name).to eq("Devops")
      expect(source.catalog_type_id).to eq("com.vmw.blueprint")
      expect(source.catalog_type).to be_a(Vra::CatalogType)
      expect(source.config).to eq({ "sourceProjectId" => "pro-123456" })
      expect(source.global?).to be_falsey
      expect(source.project_id).to eq("pro-123456")
    end
  end

  describe "#create" do
    let(:create_params) do
      {
        name: "Devops",
        catalog_type_id: "com.vmw.blueprint",
        project_id: "pro-123456",
      }
    end

    before(:each) do
      allow(client).to receive(:authorized?).and_return(true)
    end

    it "should call the create api" do
      response = double("response", code: 200, body: sample_data.to_json, success?: true)
      expect(Vra::Http).to receive(:execute)
        .with(method: :post,
              url: client.full_url("/catalog/api/admin/sources"),
              payload: {
                name: "Devops",
                typeId: "com.vmw.blueprint",
                config: {
                  sourceProjectId: "pro-123456",
                },
              }.to_json,
              headers: anything,
              verify_ssl: true)
        .and_return(response)

      described_class.create(client, create_params)
    end

    it "should create a new source" do
      response = double("response", code: 200, body: sample_data.to_json, success?: true)
      allow(Vra::Http).to receive(:execute).and_return(response)

      new_source = described_class.create(client, create_params)

      expect(new_source).to be_a(described_class)
      expect(new_source.name).to eq("Devops")
      expect(new_source.project_id).to eq("pro-123456")
    end
  end

  describe "#entitle!" do
    it "should entitle the source" do
      allow(client).to receive(:authorized?).and_return(true)
      stub_request(:get, client.full_url("/catalog/api/admin/sources/123456"))
        .to_return(status: 200, body: sample_data.to_json, headers: {})

      response = double("response", body: '{"message": "success"}', success?: true)
      allow(client).to receive(:http_post).and_return(response)

      entitle_response = described_class.entitle!(client, "123456")
      expect(entitle_response).not_to be_nil
    end
  end
end
