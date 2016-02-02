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

module Vra
  class Catalog
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def all_items
      client.http_get_paginated_array!('/catalog-service/api/consumer/catalogItems')
            .map! { |x| Vra::CatalogItem.new(client, data: x) }
    end

    def entitled_items
      client.http_get_paginated_array!('/catalog-service/api/consumer/entitledCatalogItems')
            .map! { |x| Vra::CatalogItem.new(client, data: x['catalogItem']) }
    end

    def request(*args)
      Vra::CatalogRequest.new(@client, *args)
    end
  end
end
