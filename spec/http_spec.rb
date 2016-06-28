require 'spec_helper'
require 'webmock'

describe Vra::Http do
  def expecting_request(method, url, with=nil)
    stub = stub_request(method, url)
    stub.with(with) if with
    yield if block_given?
    expect(stub).to have_been_requested
  end

  def execute(method, params)
    Vra::Http.execute(params.merge(method: method))
  end

  def get(params)
    execute :get, params
  end

  def post(params)
    execute :post, params
  end

  def head(params)
    execute :head, params
  end

  describe '#execute' do
    it 'makes a HEAD request' do
      headers = { 'X-Made-Up-Header' => 'Foo AND bar?  Are you sure?' }

      expecting_request(:head, 'http://test.local', headers: headers) do
        head url: 'http://test.local', headers: headers
      end
    end

    it 'makes a GET request' do
      headers = { 'X-Made-Up-Header' => 'Foo AND bar?  Are you sure?' }

      expecting_request(:get, 'http://test.local', headers: headers) do
        get url: 'http://test.local', headers: headers
      end
    end

    it 'makes a POST request' do
      headers = { 'X-Made-Up-Header' => 'Foo AND bar?  Are you sure?' }
      payload = 'withabodylikethis'

      expecting_request(:post, 'http://test.local', headers: headers, body: payload) do
        post url: 'http://test.local', headers: headers, payload: payload
      end
    end

    it 'preserves Location' do
      stub_request(:head, 'http://test.local')
        .to_return(headers: { 'Location' => 'http://test-location.local' })

      response = head(url: 'http://test.local')

      expect(response.location).to eq 'http://test-location.local'
    end

    it 'preserves status code' do
      stub_request(:head, 'http://test.local')
        .to_return(status: [204, 'No content'])

      response = head(url: 'http://test.local')

      expect(response.code).to eq 204
    end

    it 'configures ssl verification' do
      allow(Net::HTTP).to receive(:start).and_wrap_original do |_http, *args|
        expect(args.last).to include(verify_mode: OpenSSL::SSL::VERIFY_NONE)
        double('response', final?: true, success?: true)
      end

      execute(:get, url: 'https://test.local', verify_ssl: false)
    end

    context 'when successful' do
      it 'returns a successful response given a status 200' do
        stub_request(:head, 'http://test.local')
          .to_return(status: [200, 'Whatevs'])

        response = head(url: 'http://test.local')

        expect(response.success_ok?).to be_truthy
      end

      it 'returns a successful response given a status 204' do
        stub_request(:head, 'http://test.local')
          .to_return(status: [204, 'Whatevs'])

        response = head(url: 'http://test.local')

        expect(response.success_no_content?).to be_truthy
      end
    end

    context 'when unsuccessful' do
      (400..418).each do |status|
        it 'raises an exception given a status #{status}' do
          stub_request(:get, 'http://test.local')
            .to_return(status: [status, 'Whatevs'],
                       body: 'Error body')

          expect { get(url: 'http://test.local') }.to raise_error do |error|
            expect(error).to be_a(StandardError)
            expect(error.http_code).to eq status
            expect(error.response).to eq 'Error body'
          end
        end
      end
    end

    context 'when redirected' do
      [301, 302, 307].each do |status|
        [:get, :head].each do |method|
          it "follows #{status} redirected #{method.to_s.upcase} requests" do
            stub_request(method, 'http://test.local')
              .to_return(status: [status, 'redirect'],
                         headers: { 'Location' => 'http://test.local/redirect' })
            expecting_request(method, 'http://test.local/redirect') do
              execute(method, url: 'http://test.local')
            end
          end
        end

        it "does not follow #{status} redirected POST requests" do
          stub_request(:post, 'http://test.local')
            .to_return(status: [status, 'redirect'],
                       headers: { 'Location' => 'http://test.local/redirect' })

          expect { post(url: 'http://test.local') }.to raise_error do |error|
            expect(error).to be_a(StandardError)
            expect(error.http_code).to eq status
          end
        end
      end

      [:head, :post].each do |method|
        it "converts #{method.to_s.upcase} to GET on 303 redirect" do
          stub_request(method, 'http://test.local')
            .to_return(status: [303, 'See Other'],
                       headers: { 'Location' => 'http://test.local/redirect' })

          expecting_request(:get, 'http://test.local/redirect') do
            execute method, url: 'http://test.local'
          end
        end
      end
    end
  end
end
