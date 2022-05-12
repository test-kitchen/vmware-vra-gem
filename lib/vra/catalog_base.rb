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
  # Base class with common methods
  class CatalogBase
    attr_reader :id

    # @param client [Vra::Client] - a vra client object
    # @param opts [Hash] - Contains the either id of the catalog or the data hash
    # Either one of id or data hash is required, must not supply both
    def initialize(client, opts)
      @client = client
      @id     = opts[:id]
      @data   = opts[:data]
    end

    def entitle!(opts = {})
      response = client.http_post(
        "/catalog/api/admin/entitlements?project_id=#{project_id}",
        FFI_Yajl::Encoder.encode(entitle_params(opts[:type])),
        opts[:skip_auth] || false
      )

      FFI_Yajl::Parser.parse(response.body)
    end

    private

    attr_reader :client, :data

    def validate!
      raise ArgumentError, "must supply id or data hash" if @id.nil? && @data.nil?
      raise ArgumentError, "must supply id or data hash, not both" if !@id.nil? && !@data.nil?
    end

    def entitle_params(type)
      {
        'projectId': project_id,
        'definition': {
          'type': type,
          'id': id,
        },
      }
    end
  end
end
