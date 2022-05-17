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
module Vra
  # Class that represents the Catalog Type
  class CatalogType < Vra::CatalogBase
    INDEX_URL = "/catalog/api/types"

    def initialize(client, opts = {})
      super
      validate!
      fetch_data
    end

    def name
      data["name"]
    end

    def base_url
      data["baseUri"]
    end

    def config_schema
      data["configSchema"]
    end

    def icon_id
      data["iconId"]
    end

    private

    def fetch_data
      @id = data["id"] and return unless data.nil?

      @data = client.get_parsed("/catalog/api/types/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "catalog type ID #{id} does not exist"
    end
  end
end
