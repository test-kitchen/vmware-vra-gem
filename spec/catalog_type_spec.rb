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

describe Vra::CatalogType do
  let(:client) do
    Vra::Client.new(
      username: "user@corp.local",
      password: "password",
      tenant: "tenant",
      base_url: "https://vra.corp.local"
    )
  end

  let(:sample_data) do
    JSON.parse(File.read("spec/fixtures/resource/sample_catalog_type.json"))
  end

  describe "#initialize" do
    let(:cat_type) do
      described_class.allocate
    end

    before(:each) do
      allow(client).to receive(:get_parsed).and_return(sample_data)
    end

    it "should validate and fetch data" do
      expect(cat_type).to receive(:validate!)
      expect(cat_type).to receive(:fetch_data)

      cat_type.send(:initialize, client, id: "com.vmw.vro.workflow")
    end

    it "should fetch data when id is passed" do
      cat_type.send(:initialize, client, id: "com.vmw.vro.workflow")

      expect(cat_type.send(:data)).not_to be_nil
    end

    it "should set id when data is passed" do
      cat_type.send(:initialize, client, data: sample_data)

      expect(cat_type.id).to eq("com.vmw.vro.workflow")
    end
  end

  describe "#validate" do
    let(:cat_type) do
      described_class.allocate
    end

    it "should raise exception when neither id nor data passed" do
      expect { cat_type.send(:initialize, client) }.to raise_error(ArgumentError)
    end

    it "should raise exception when both id and data is passed" do
      params = [client, { id: "com.vmw.vra.workflow", data: sample_data }]
      expect { cat_type.send(:initialize, *params) }.to raise_error(ArgumentError)
    end
  end

  describe "#fetch_data" do
    let(:cat_type) do
      described_class.allocate
    end

    it "should fetch the data correctly" do
      allow(client).to receive(:get_parsed).and_return(sample_data)
      cat_type.send(:initialize, client, id: "com.vmw.vro.workflow")

      data = cat_type.send(:data)
      expect(data).not_to be_nil
      expect(cat_type.id).to eq(data["id"])
      expect(data["name"]).to eq("vRealize Orchestrator Workflow")
    end

    it "should raise when catalog with type not found" do
      allow(client).to receive(:get_parsed).and_raise(Vra::Exception::HTTPNotFound)

      expect { cat_type.send(:initialize, client, id: sample_data["id"]) }
        .to raise_error(Vra::Exception::NotFound)
        .with_message("catalog type ID #{sample_data["id"]} does not exist")
    end
  end

  describe "attributes" do
    it "should have the correct attributes" do
      allow(client).to receive(:get_parsed).and_return(sample_data)

      cat_type = described_class.new(client, id: sample_data["id"])
      expect(cat_type.name).to eq("vRealize Orchestrator Workflow")
      expect(cat_type.base_url).to eq("https://vra.corp.local:8080/vro")
      expect(cat_type.config_schema).to eq(sample_data["configSchema"])
      expect(cat_type.icon_id).to eq("0616ff81-c13b-32fe-b3b9-de3c2edd85dd")
    end
  end
end
