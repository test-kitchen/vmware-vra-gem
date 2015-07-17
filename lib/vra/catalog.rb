require 'json'

module Vra
  class Catalog
    def initialize(client)
      @client = client
    end

    def all_items
      @client.http_get_paginated_array!('/catalog-service/api/consumer/catalogItems')
    end

    def entitled_items
      @client.http_get_paginated_array!('/catalog-service/api/consumer/entitledCatalogItems')
    end

    def request(*args)
      Vra::CatalogRequest.new(@client, *args)
    end
  end
end
