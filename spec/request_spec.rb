require 'spec_helper'

shared_examples 'refresh_trigger_method' do |method|
  it 'calls #refresh_if_needed' do
    expect(@request).to receive(:refresh_if_empty)
    @request.send(method)
  end

  it 'returns nil if request data is empty' do
    allow(@request).to receive(:refresh_if_empty)
    allow(@request).to receive(:request_empty?).and_return true
    expect(@request.send(method)).to eq nil
  end
end

describe Vra::Request do
  let(:request_id) { '2c3df007-b1c4-4687-b332-310089c4851d' }

  let(:in_progress_payload) do
    {
      'phase' => 'IN_PROGRESS',
      'requestCompletion' => {
        'requestCompletionState' => nil,
        'completionDetails' => nil
      }
    }
  end

  let(:completed_payload) do
    {
      'phase' => 'SUCCESSFUL',
      'requestCompletion' => {
        'requestCompletionState' => 'SUCCESSFUL',
        'completionDetails' => 'Request succeeded. Created test-machine.'
      }
    }
  end

  before(:each) do
    @request = Vra::Request.new(@vra, request_id)
  end

  describe '#initialize' do
    it 'sets the id' do
      expect(@request.id).to eq request_id
    end
  end

  describe '#refresh' do
    it 'calls the request API endpoint' do
      expect(@vra).to receive(:http_get!)
        .with("/catalog-service/api/consumer/requests/#{request_id}")
        .and_return(in_progress_payload.to_json)

      @request.refresh
    end
  end

  describe '#refresh_if_empty' do
    context 'request data is empty' do
      it 'calls #refresh' do
        expect(@request).to receive(:refresh)
        @request.refresh_if_empty
      end
    end

    context 'request data is not empty' do
      it 'does not call #refresh' do
        allow(@request).to receive(:request_empty?).and_return(false)
        expect(@request).to_not receive(:refresh)
      end
    end
  end

  describe '#status' do
    it_behaves_like 'refresh_trigger_method', :status
  end

  describe '#completion_state' do
    it_behaves_like 'refresh_trigger_method', :completion_state
  end

  describe '#completion_details' do
    it_behaves_like 'refresh_trigger_method', :completion_details
  end

  describe '#resources' do
    it 'calls the requests resources API endpoint' do
      expect(@vra).to receive(:http_get_paginated_array!)
        .with("/catalog-service/api/consumer/requests/#{request_id}/resources")
        .and_return([])

      @request.resources
    end
  end
end
