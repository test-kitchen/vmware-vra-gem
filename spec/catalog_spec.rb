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

describe Vra::Catalog do
  let(:client) do
    Vra::Client.new(
      username: "user@corp.local",
      password: "password",
      tenant: "tenant",
      base_url: "https://vra.corp.local"
    )
  end

  let(:catalog_item) do
    JSON.parse(File.read("spec/fixtures/resource/sample_catalog_item.json"))
  end

  let(:entitled_catalog_item) do
    JSON.parse(File.read("spec/fixtures/resource/sample_catalog_item_2.json"))
  end

  before(:each) do
    allow(client).to receive(:authorized?).and_return(true)
  end

  describe "#all_items" do
    it "calls the catalogItems endpoint" do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog/api/items", nil)
        .and_return([catalog_item])

      client.catalog.all_items
    end

    it "returns a Vra::CatalogItem object" do
      allow(client).to receive(:http_get_paginated_array!)
<<<<<<< HEAD
        .with("/catalog/api/admin/items", nil)
=======
        .with('/catalog/api/items', nil)
>>>>>>> c039d0a (Use Items catalog endpoint rather than Admin endpoint to fetch all entitled catalog items for current user)
        .and_return([catalog_item])

      items = client.catalog.all_items

      expect(items.first).to be_an_instance_of(Vra::CatalogItem)
    end
  end

  describe "#entitled_items" do
    it "calls the entitledCatalogItems endpoint" do
      expect(client).to receive(:get_parsed)
        .with("/catalog/api/admin/entitlements?projectId=pro-123456")
        .and_return(JSON.parse(File.read("spec/fixtures/resource/sample_entitlements.json")))

      client.catalog.entitled_items("pro-123456")
    end

    it "returns a Vra::CatalogItem object" do
      allow(client).to receive(:get_parsed)
        .with("/catalog/api/admin/entitlements?projectId=pro-123456")
        .and_return(JSON.parse(File.read("spec/fixtures/resource/sample_entitlements.json")))

      items = client.catalog.entitled_items("pro-123456")

      expect(items.first).to be_an_instance_of(Vra::CatalogItem)
    end

    it "return a Vra::CatalogSource object on source entitlements" do
      allow(client).to receive(:get_parsed)
        .with("/catalog/api/admin/entitlements?projectId=pro-123456")
        .and_return(JSON.parse(File.read("spec/fixtures/resource/sample_entitlements.json")))

      items = client.catalog.entitled_sources("pro-123456")

      expect(items.first).to be_an_instance_of(Vra::CatalogSource)
    end
  end

  describe "#request" do
    it "returns a new Vra::CatalogRequest object" do
      allow(Vra::CatalogItem).to receive(:new)
      request = client.catalog.request("blueprint-1", cpus: 2)
      expect(request).to be_an_instance_of(Vra::DeploymentRequest)
    end
  end

  describe "#sources" do
    let(:source_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_catalog_source.json"))
    end

    it "should call the api to fetch the sources" do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog/api/admin/sources", nil)
        .and_return([source_data])

      client.catalog.all_sources
    end

    it "should return the Vra::CatalogSource object" do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog/api/admin/sources", nil)
        .and_return([source_data])

      source = client.catalog.all_sources.first

      expect(source).to be_a(Vra::CatalogSource)
    end
  end

  describe "#types" do
    let(:type_data) do
      JSON.parse(File.read("spec/fixtures/resource/sample_catalog_type.json"))
    end

    it "should call the api to fetch the types" do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog/api/types", nil)
        .and_return([type_data])

      client.catalog.all_types
    end

    it "should return the Vra::CatalogType object" do
      expect(client).to receive(:http_get_paginated_array!)
        .with("/catalog/api/types", nil)
        .and_return([type_data])

      source = client.catalog.all_types.first

      expect(source).to be_a(Vra::CatalogType)
    end
  end

  describe "#fetch_catalog_by_name" do
    let(:catalog_item) do
      JSON.parse(File.read("spec/fixtures/resource/sample_catalog_item.json"))
    end

    it "returns the catalogs by name" do
      expect(client).to receive(:http_get_paginated_array!)
<<<<<<< HEAD
        .with("/catalog/api/admin/items", "search=centos")
=======
        .with('/catalog/api/items', 'search=centos')
>>>>>>> c039d0a (Use Items catalog endpoint rather than Admin endpoint to fetch all entitled catalog items for current user)
        .and_return([catalog_item])

      cat = client.catalog.fetch_catalog_items("centos").first

      expect(cat).to be_an_instance_of(Vra::CatalogItem)
    end
  end
end
