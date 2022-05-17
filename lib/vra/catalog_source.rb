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
require "ffi_yajl" unless defined?(FFI_Yajl)

module Vra
  # Class that represents the Catalog Source
  class CatalogSource < Vra::CatalogBase
    INDEX_URL = "/catalog/api/admin/sources"

    # @param client [Vra::Client] - a vra client object
    # @param opts [Hash] - Contains the either id of the catalog or the data hash
    # Either one of id or data hash is required, must not supply both
    def initialize(client, opts)
      super
      validate!
      fetch_data
    end

    def name
      data["name"]
    end

    def catalog_type_id
      data["typeId"]
    end

    def catalog_type
      @catalog_type ||= Vra::CatalogType.new(client, id: catalog_type_id)
    end

    def config
      data["config"]
    end

    def global?
      data["global"] == true
    end

    def project_id
      config["sourceProjectId"]
    end

    def entitle!(opts = {})
      super(opts.merge(type: "CatalogSourceIdentifier"))
    end

    class << self
      # Method to create a catalog source
      def create(client, opts)
        validate_create!(opts)

        response = client.http_post(
          "/catalog/api/admin/sources",
          FFI_Yajl::Encoder.encode(create_params(opts)),
          opts[:skip_auth] || false
        )

        return false unless response.success?

        new(client, data: FFI_Yajl::Parser.parse(response.body))
      end

      def entitle!(client, id)
        new(client, id: id).entitle!
      end

      private

      def validate_create!(opts)
        %i{name catalog_type_id project_id}.each do |arg|
          raise ArgumentError, "#{arg} param is required to perform the create action" unless opts.key?(arg)
        end
      end

      def create_params(opts)
        {
          'name': opts[:name],
          'typeId': opts[:catalog_type_id],
          'config': {
            'sourceProjectId': opts[:project_id],
          },
        }
      end
    end

    private

    def fetch_data
      fetch_catalog_data && return if data.nil?

      @id = data["id"]
    end

    def fetch_catalog_data
      @data = client.get_parsed("/catalog/api/admin/sources/#{id}")
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "catalog source ID #{id} does not exist"
    end
  end
end
