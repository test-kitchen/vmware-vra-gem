require 'spec_helper'

describe Vra::Requests do
  before(:each) do
    @requests = Vra::Requests.new(@vra)
  end

  describe '#all_resources' do
    it 'calls the requests API endpoint' do
      expect(@vra).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/requests')
        .and_return([])

      @requests.all_requests
    end

    it 'returns an array of request objects' do
      allow(@vra).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/requests')
        .and_return([ { 'id' => '1' }, { 'id' => '2' } ])

      items = @requests.all_requests

      expect(items[0]).to be_an_instance_of(Vra::Request)
      expect(items[1]).to be_an_instance_of(Vra::Request)
    end
  end

  describe '#by_id' do
    it 'returns a request object' do
      expect(Vra::Request).to receive(:new).with(@vra, '12345')

      @requests.by_id('12345')
    end
  end
end
