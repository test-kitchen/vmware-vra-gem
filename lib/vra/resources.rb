module Vra
  class Resources
    def initialize(client)
      @client = client
    end

    def all_resources
      resources = []

      items = @client.http_get_paginated_array!('/catalog-service/api/consumer/resources')
      items.each do |item|
        resources << Vra::Resource.new(@client, data: item)
      end

      resources
    end

    def by_id(id)
      Vra::Resource.new(@client, id: id)
    end
  end
end
