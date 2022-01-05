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
  # class that represents the Deployments Object
  class Deployments
    def initialize(client)
      @client = client
    end

    def by_id(dep_id)
      Vra::Deployment.new(client, id: dep_id)
    end

    def all
      fetch_all_resources
    end

    class << self
      def all(client)
        new(client).all
      end

      def by_id(client, id)
        new(client).by_id(id)
      end
    end

    private

    attr_reader :client

    def fetch_all_resources
      client
        .http_get_paginated_array!('/deployment/api/deployments')
        .map! { |x| Vra::Deployment.new(client, data: x) }
    end
  end
end
