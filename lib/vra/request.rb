module Vra
  class Request
    attr_reader :id
    def initialize(client, id)
      @client = client
      @id     = id

      @request_data       = nil
      @status             = nil
      @completion_state   = nil
      @completion_details = nil
    end

    def refresh
      @request_data = JSON.load(@client.http_get!("/catalog-service/api/consumer/requests/#{@id}"))
    rescue Vra::Exception::HTTPNotFound
      raise Vra::Exception::NotFound, "request ID #{@id} is not found"
    end

    def refresh_if_empty
      refresh if request_empty?
    end

    def request_empty?
      @request_data.nil?
    end

    def status
      refresh_if_empty
      return if request_empty?

      @request_data['phase']
    end

    def completion_state
      refresh_if_empty
      return if request_empty?

      @request_data['requestCompletion']['requestCompletionState']
    end

    def completion_details
      refresh_if_empty
      return if request_empty?

      @request_data['requestCompletion']['completionDetails']
    end

    def resources
      resources = []

      begin
        request_resources = @client.http_get_paginated_array!("/catalog-service/api/consumer/requests/#{@id}/resources")
      rescue Vra::Exception::HTTPNotFound
        raise Vra::Exception::NotFound, "resources for request ID #{@id} are not found"
      end

      request_resources.each do |resource|
        resources << Vra::Resource.new(@client, data: resource)
      end

      resources
    end
  end
end
