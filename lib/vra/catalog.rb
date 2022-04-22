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

module Vra
  class Catalog
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def all_types
      fetch_resources Vra::CatalogType
    end

    def all_sources
      fetch_resources Vra::CatalogSource
    end

    def all_items
      fetch_resources Vra::CatalogItem
    end

    def entitled_sources(project_id)
      fetch_entitlements(project_id, 'CatalogSourceIdentifier')
    end

    def entitled_items(project_id)
      fetch_entitlements(project_id, 'CatalogItemIdentifier')
    end

    def request(*args)
      Vra::DeploymentRequest.new(@client, *args)
    end

    def fetch_catalog_items(catalog_name)
      fetch_resources(
        Vra::CatalogItem,
        '/catalog/api/items',
        "search=#{catalog_name}"
      )
    end

    private

    def fetch_resources(klass, url = nil, filter = nil)
      client
        .http_get_paginated_array!(url || klass::INDEX_URL, filter)
        .map! { |x| klass.new(client, data: x) }
    end

    def fetch_entitlements(project_id, type)
      klass = type == 'CatalogSourceIdentifier' ? Vra::CatalogSource : Vra::CatalogItem

      client
        .get_parsed("/catalog/api/admin/entitlements?projectId=#{project_id}")
        .select { |x| x['definition']['type'] == type }
        .map! { |x| klass.new(client, data: x['definition']) }
    end
  end
end
