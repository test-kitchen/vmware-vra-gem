require 'spec_helper'

describe Vra::Catalog do
  describe '#all_items' do
    it 'calls the catalogItems endpoint' do
      expect(@vra).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/catalogItems')

      @vra.catalog.all_items
    end
  end

  describe '#entitled_items' do
    it 'calls the entitledCatalogItems endpoint' do
      expect(@vra).to receive(:http_get_paginated_array!).with('/catalog-service/api/consumer/entitledCatalogItems')

      @vra.catalog.entitled_items
    end
  end

  describe '#request' do
    it 'returns a new Vra::CatalogRequest object' do
      request = @vra.catalog.request('blueprint-1', cpus: 2)
      expect(request).to be_an_instance_of(Vra::CatalogRequest)
    end
  end
end
