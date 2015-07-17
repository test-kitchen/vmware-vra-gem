require 'spec_helper'

describe Vra::Client do
  describe '#request_headers' do
    context 'when bearer token exists' do
      it 'has an Authorization header' do
        @vra.bearer_token = '12345'
        expect(@vra.request_headers.key?('Authorization')).to be true
      end
    end

    context 'when bearer token does not exist' do
      it 'has an Authorization header' do
        expect(@vra.request_headers.key?('Authorization')).to be false
      end
    end
  end

  describe '#authorize!' do
    context 'when a token is not authorized or no token exists' do
      it 'generates a token successfully' do
        allow(@vra).to receive(:authorized?).twice.and_return(false, true)
        expect(@vra).to receive(:generate_bearer_token)

        @vra.authorize!
      end

      it 'raises an exception if token generation fails' do
        allow(@vra).to receive(:authorized?).and_return(false)
        allow(@vra).to receive(:generate_bearer_token).and_raise(Vra::Exception::Unauthorized)

        expect { @vra.authorize! }.to raise_error(Vra::Exception::Unauthorized)
      end

      it 'raises an exception if a generated token is unauthorized' do
        allow(@vra).to receive(:authorized).twice.and_return(false, false)
        allow(@vra).to receive(:generate_bearer_token)

        expect { @vra.authorize! }.to raise_error(Vra::Exception::Unauthorized)
      end
    end

    context 'when a token is authorized' do
      it 'does not generate a new token' do
        allow(@vra).to receive(:authorized?).and_return(true)
        expect(@vra).to_not receive(:generate_bearer_token)

        @vra.authorize!
      end
    end
  end

  describe '#authorized?' do
    context 'when token does not exist' do
      it 'returns false' do
        expect(@vra.authorized?).to be false
      end
    end

    context 'when token exists' do
      before(:each) do
        @vra.bearer_token = '12345'
      end

      url = '/identity/api/tokens/12345'

      it 'returns true if the token validates successfully' do
        response = double('response')
        allow(response).to receive(:code).and_return(204)
        allow(@vra).to receive(:http_head).with(url, :skip_auth).and_return(response)

        expect(@vra.authorized?).to be true
      end

      it 'returns false if the token validates unsuccessfully' do
        response = double('response')
        allow(response).to receive(:code).and_return(500)
        allow(@vra).to receive(:http_head).with(url, :skip_auth).and_return(response)

        expect(@vra.authorized?).to be false
      end
    end
  end

  describe '#generate_bearer_token' do
    payload = {
      'username' => 'user@corp.local',
      'password' => 'password',
      'tenant'   => 'tenant'
    }.to_json

    it 'posts to the tokens API endpoint' do
      response = double('response')
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:body).and_return('{"id":"12345"}')
      expect(@vra).to receive(:http_post).with('/identity/api/tokens',
                                               payload,
                                               :skip_auth).and_return(response)

      @vra.generate_bearer_token
    end

    context 'when token is generated successfully' do
      it 'sets the token' do
        response = double('response')
        allow(response).to receive(:code).and_return(200)
        allow(response).to receive(:body).and_return('{"id":"12345"}')
        allow(@vra).to receive(:http_post).with('/identity/api/tokens',
                                                payload,
                                                :skip_auth).and_return(response)

        @vra.generate_bearer_token

        expect(@vra.bearer_token).to eq '12345'
      end
    end

    context 'when token is not generated successfully' do
      it 'raises an exception' do
        response = double('response')
        allow(response).to receive(:code).and_return(500)
        allow(response).to receive(:body).and_return('error string')
        allow(@vra).to receive(:http_post).with('/identity/api/tokens',
                                                payload,
                                                :skip_auth)
          .and_return(response)

        expect { @vra.generate_bearer_token }.to raise_error(Vra::Exception::Unauthorized)
      end
    end
  end

  describe '#full_url' do
    it 'returns a properly formatted url' do
      expect(@vra.full_url('/mypath')).to eq 'https://vra.corp.local/mypath'
    end
  end

  describe '#http_head' do
    context 'when skip_auth is nil' do
      it 'authorizes before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to receive(:authorize!)

        @vra.http_head('/test')
      end
    end

    context 'when skip_auth is not nil' do
      it 'does not authorize before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to_not receive(:authorize!)

        @vra.http_head('/test', :skip_auth)
      end
    end

    it 'calls RestClient::Request#execute' do
      response   = double('response')
      path       = '/test'
      full_url   = 'https://vra.corp.local/test'
      headers    = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      verify_ssl = true

      allow(@vra).to receive(:authorize!)
      expect(RestClient::Request).to receive(:execute).with(method: :head,
                                                            url: full_url,
                                                            headers: headers,
                                                            verify_ssl: verify_ssl)
        .and_return(response)

      @vra.http_head(path)
    end
  end

  describe '#http_get' do
    context 'when skip_auth is nil' do
      it 'authorizes before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to receive(:authorize!)

        @vra.http_get('/test')
      end
    end

    context 'when skip_auth is not nil' do
      it 'does not authorize before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to_not receive(:authorize!)

        @vra.http_get('/test', :skip_auth)
      end
    end

    it 'calls RestClient::Request#execute' do
      response   = double('response')
      path       = '/test'
      full_url   = 'https://vra.corp.local/test'
      headers    = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      verify_ssl = true

      allow(@vra).to receive(:authorize!)
      expect(RestClient::Request).to receive(:execute).with(method: :get,
                                                            url: full_url,
                                                            headers: headers,
                                                            verify_ssl: verify_ssl)
        .and_return(response)

      @vra.http_get(path)
    end

    it 'calls raise_http_exception upon a RestClient error' do
      allow(@vra).to receive(:authorize!)
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::ResourceNotFound)
      expect(@vra).to receive(:raise_http_exception)

      @vra.http_get('/404')
    end
  end

  describe '#http_get!' do
    it 'returns the response body' do
      response = double('response', body: 'body text')
      allow(@vra).to receive(:http_get).with('/test').and_return(response)

      expect(@vra.http_get!('/test')).to eq 'body text'
    end
  end

  describe '#http_get_paginated_array!' do
    it 'allows a limit override' do
      expect(@vra).to receive(:http_get!)
        .with('/test?limit=10&page=1')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 1 } }.to_json)

      @vra.http_get_paginated_array!('/test', 10)
    end

    it 'only calls http_get! once when total pages is 0 (no items)' do
      expect(@vra).to receive(:http_get!)
        .once
        .with('/test?limit=20&page=1')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 0 } }.to_json)

      @vra.http_get_paginated_array!('/test')
    end

    it 'only calls http_get! once when total pages is 1' do
      expect(@vra).to receive(:http_get!)
        .once
        .with('/test?limit=20&page=1')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 1 } }.to_json)

      @vra.http_get_paginated_array!('/test')
    end

    it 'calls http_get! 3 times if there are 3 pages of response' do
      expect(@vra).to receive(:http_get!)
        .with('/test?limit=20&page=1')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 3 } }.to_json)
      expect(@vra).to receive(:http_get!)
        .with('/test?limit=20&page=2')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 3 } }.to_json)
      expect(@vra).to receive(:http_get!)
        .with('/test?limit=20&page=3')
        .and_return({ 'content' => [], 'metadata' => { 'totalPages' => 3 } }.to_json)

      @vra.http_get_paginated_array!('/test')
    end
  end

  describe '#http_post' do
    context 'when skip_auth is nil' do
      it 'authorizes before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to receive(:authorize!)

        @vra.http_post('/test', 'some payload')
      end
    end

    context 'when skip_auth is not nil' do
      it 'does not authorize before proceeding' do
        response = double('response')
        allow(RestClient::Request).to receive(:execute).and_return(response)
        expect(@vra).to_not receive(:authorize!)

        @vra.http_post('/test', 'some payload', :skip_auth)
      end
    end

    it 'calls RestClient::Request#execute' do
      response   = double('response')
      path       = '/test'
      full_url   = 'https://vra.corp.local/test'
      headers    = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      payload    = 'some payload'
      verify_ssl = true

      allow(@vra).to receive(:authorize!)
      expect(RestClient::Request).to receive(:execute).with(method: :post,
                                                            url: full_url,
                                                            headers: headers,
                                                            payload: payload,
                                                            verify_ssl: verify_ssl)
        .and_return(response)

      @vra.http_post(path, payload)
    end

    it 'calls raise_http_exception upon a RestClient error' do
      allow(@vra).to receive(:authorize!)
      allow(RestClient::Request).to receive(:execute).and_raise(RestClient::ResourceNotFound)
      expect(@vra).to receive(:raise_http_exception)

      @vra.http_post('/404', 'test payload')
    end
  end

  describe '#http_post!' do
    it 'returns the response body' do
      response = double('response', body: 'body text')
      allow(@vra).to receive(:http_post).with('/test', 'test payload').and_return(response)

      expect(@vra.http_post!('/test', 'test payload')).to eq 'body text'
    end
  end

  describe '#raise_http_exception' do
    context 'when a 404 is received' do
      let(:exception) do
        double('RestClient::ResourceNotFound',
               http_code: 404,
               message: 'Not Found',
               response: '404 Not Found')
      end

      it 'raises a Vra::Exception::HTTPNotFound exception' do
        expect { @vra.raise_http_exception(exception, '/test') }.to raise_error(Vra::Exception::HTTPNotFound)
      end
    end

    context 'when an unspecified http error is received' do
      let(:exception) do
        double('RestClient::BadRequest',
               http_code: 400,
               message: 'Bad Request',
               response: '400 Bad Request')
      end

      it 'raises a Vra::Exception::HTTPError exception' do
        expect { @vra.raise_http_exception(exception, '/test') }.to raise_error(Vra::Exception::HTTPError)
      end
    end
  end
end
