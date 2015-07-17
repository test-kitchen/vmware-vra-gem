require 'spec_helper'

describe Vra::Resources do
  before(:each) do
    @resources = Vra::Resources.new(@vra)
  end

  describe '#all_resources' do
    it 'calls the resources API endpoint' do
      expect(@vra).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/resources')
        .and_return([])

      @resources.all_resources
    end

    it 'returns an array of resource objects' do
      allow(@vra).to receive(:http_get_paginated_array!)
        .with('/catalog-service/api/consumer/resources')
        .and_return([ { 'id' => '1' }, { 'id' => '2' } ])

      items = @resources.all_resources

      expect(items[0]).to be_an_instance_of(Vra::Resource)
      expect(items[1]).to be_an_instance_of(Vra::Resource)
    end
  end

  describe '#by_id' do
    it 'returns a resource object' do
      expect(Vra::Resource).to receive(:new).with(@vra, id: '12345')

      @resources.by_id('12345')
    end
  end
end
