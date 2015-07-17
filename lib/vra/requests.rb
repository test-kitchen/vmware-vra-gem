module Vra
  class Requests
    def initialize(client)
      @client = client
    end

    def all_requests
      requests = []

      items = @client.http_get_paginated_array!('/catalog-service/api/consumer/requests')
      items.each do |item|
        requests << Vra::Request.new(@client, item['id'])
      end

      requests
    end

    def by_id(id)
      Vra::Request.new(@client, id)
    end
  end
end
