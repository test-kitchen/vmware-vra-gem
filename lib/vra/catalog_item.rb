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

require "ffi_yajl" unless defined?(FFI_Yajl)
require "vra/catalog"

module Vra
  # Class that represents the Catalog Item
  class CatalogItem < Vra::CatalogBase
    INDEX_URL = "/catalog/api/items"

    attr_reader :project_id

    def initialize(client, opts = {})
      super
      @project_id = opts[:project_id]
      validate!

      if @data.nil?
        fetch_catalog_item
      else
        @id = @data["id"]
      end
    end

    def fetch_catalog_item
      @data = client.get_parsed("/catalog/api/items/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "catalog ID #{id} does not exist"
    end

    def name
      data["name"]
    end

    def description
      data["description"]
    end

    def source_id
      data["sourceId"]
    end

    def source_name
      data["sourceName"]
    end

    def source
      @source ||= Vra::CatalogSource.new(client, id: source_id)
    end

    def type
      @type ||= Vra::CatalogType.new(client, data: data["type"])
    end

    def icon_id
      data["iconId"]
    end

    def versions
      client
        .http_get_paginated_array!("/catalog/api/items/#{id}/versions")
        .map { |v| v["id"] }
    end

    def entitle!(opts = {})
      super(opts.merge(type: "CatalogItemIdentifier"))
    end

    class << self
      def entitle!(client, id)
        new(client, id: id).entitle!
      end

      def fetch_latest_version(client, id)
        new(client, data: { "id" => id }).versions&.first
      end
    end
  end
end
