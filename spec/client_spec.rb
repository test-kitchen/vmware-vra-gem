# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2022 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "pry"
# require 'pry-byebug'

describe Vra::Client do
  let(:client_params) do
    {
      username: "user@corp.local",
      password: "password",
      domain: "domain",
      base_url: "https://vra.corp.local",
    }
  end

  let(:client) do
    described_class.new(client_params)
  end

  let(:client_without_ssl) do
    described_class.new(client_params.merge(verify_ssl: false))
  end

  describe "#initialize" do
    it "calls validate_client_options!" do
      client = described_class.allocate
      expect(client).to receive(:validate_client_options!)
      client.send(:initialize, client_params)
    end
  end

  describe "#token_params" do
    it "gets the correct password from the PasswordMasker object" do
      expect(client.token_params[:password]).to eq("password")
    end
  end

  describe "#request_headers" do
    context "when access token exists" do
      it "has an Authorization header" do
        client.access_token = "12345"
        expect(client.request_headers.key?("Authorization")).to be true
      end
    end

    context "when access token does not exist" do
      it "does not have an Authorization header" do
        expect(client.request_headers.key?("Authorization")).to be false
      end
    end
  end

  describe "#authorize!" do
    context "when a token is not authorized or no token exists" do
      it "generates a token successfully" do
        allow(client).to receive(:authorized?).twice.and_return(false, true)
        expect(client).to receive(:generate_access_token)

        client.authorize!
      end

      it "raises an exception if token generation fails" do
        allow(client).to receive(:authorized?).and_return(false)
        allow(client).to receive(:generate_access_token).and_raise(Vra::Exception::Unauthorized)

        expect { client.authorize! }.to raise_error(Vra::Exception::Unauthorized)
      end

      it "raises an exception if a generated token is unauthorized" do
        allow(client).to receive(:authorized).twice.and_return(false, false)
        allow(client).to receive(:generate_access_token)

        expect { client.authorize! }.to raise_error(Vra::Exception::Unauthorized)
      end
    end

    context "when a token is authorized" do
      it "does not generate a new token" do
        allow(client).to receive(:authorized?).and_return(true)
        expect(client).to_not receive(:generate_access_token)

        client.authorize!
      end
    end
  end

  describe "#authorized?" do
    context "when token does not exist" do
      it "returns false" do
        expect(client.authorized?).to be false
      end
    end

    context "when token exists" do
      before(:each) do
        client.access_token  = "12345"
        client.refresh_token = "54321"
      end

      it "returns true if the token validates successfully" do
        response = double("response", success_no_content?: true, code: 204, success?: true)
        allow(Vra::Http).to receive(:execute).and_return(response)

        expect(client.authorized?).to be true
      end

      it "returns false if the token validates unsuccessfully" do
        response = double("response", success_no_content?: false, code: 401, success?: false)
        allow(Vra::Http).to receive(:execute).and_return(response)

        expect(client.authorized?).to be false
      end
    end
  end

  describe "#generate_access_token" do
    let(:payload) do
      {
        username: "user@corp.local",
        password: "password",
        domain: "domain",
      }.to_json
    end

    let(:success_response) do
      {
        access_token: "123456",
        refresh_token: "654321",
        id: "123456",
      }.to_json
    end

    let(:refresh_response_body) { { token: "123456" }.to_json }

    it "posts to the tokens API endpoint" do
      response = double("response", code: 200, body: success_response, success_ok?: true)
      refresh_response = double("response", code: 200, body: refresh_response_body, success_ok?: true)
      # First request to generate the refresh token
      expect(Vra::Http).to receive(:execute)
        .with(method: :post,
              url: client.full_url(described_class::REFRESH_TOKEN_URL),
              payload: payload,
              headers: anything,
              verify_ssl: true)
        .and_return(response)

      # Second request to generate access token
      expect(Vra::Http).to receive(:execute)
        .with(method: :post,
              url: client.full_url(described_class::ACCESS_TOKEN_URL),
              payload: "{ \"refreshToken\": \"654321\" }",
              headers: anything,
              verify_ssl: true)
        .and_return(refresh_response)

      client.generate_access_token
    end

    context "when token is generated successfully" do
      it "sets the token" do
        response = double("response", code: 200, body: success_response, success_ok?: true)
        refresh_response = double("response", code: 200, body: refresh_response_body, success_ok?: true)
        allow(Vra::Http).to receive(:execute).twice.and_return(response, refresh_response)

        client.generate_access_token

        expect(client.access_token).to eq "123456"
        expect(client.refresh_token).to eq "654321"
      end
    end

    context "when token is not generated successfully" do
      it "raises an exception" do
        response = double("response", code: 400, body: "error string", success_ok?: false)
        allow(Vra::Http).to receive(:execute).and_return(response)

        expect { client.generate_access_token }.to raise_error(Vra::Exception::Unauthorized)
      end
    end
  end

  describe "#full_url" do
    it "returns a properly formatted url" do
      expect(client.full_url("/url_path")).to eq "https://vra.corp.local/url_path"
    end
  end

  describe "#http_head" do
    context "when skip_auth is nil" do
      it "authorizes before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to receive(:authorize!)

        client.http_head("/test")
      end
    end

    context "when skip_auth is not nil" do
      it "does not authorize before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to_not receive(:authorize!)

        client.http_head("/test", :skip_auth)
      end
    end

    it "calls Vra::Http.execute" do
      response   = double("response")
      path       = "/test"
      full_url   = "https://vra.corp.local/test"
      headers    = { "Accept" => "application/json", "Content-Type" => "application/json" }
      verify_ssl = true

      allow(client).to receive(:authorize!)

      expect(Vra::Http).to receive(:execute)
        .with(method: :head,
              url: full_url,
              headers: headers,
              verify_ssl: verify_ssl)
        .and_return(response)

      client.http_head(path)
    end

    it "calls Vra::Http.execute with verify_ssl false" do
      response   = double("response")
      path       = "/test"
      full_url   = "https://vra.corp.local/test"
      headers    = { "Accept" => "application/json", "Content-Type" => "application/json" }
      verify_ssl = false

      allow(client_without_ssl).to receive(:authorize!)
      expect(Vra::Http).to receive(:execute)
        .with(method: :head,
              url: full_url,
              headers: headers,
              verify_ssl: verify_ssl)
        .and_return(response)

      client_without_ssl.http_head(path)
    end

    it "raises an HTTPNotFound on a 404 error" do
      allow(client).to receive(:authorize!)
      allow(Vra::Http).to receive(:execute)
        .and_raise(Vra::Http::Error.new("message", 404, "Not Found"))

      expect { client.http_head("/404") }.to raise_error(Vra::Exception::HTTPNotFound)
    end
  end

  describe "#http_get" do
    context "when skip_auth is nil" do
      it "authorizes before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to receive(:authorize!)

        client.http_get("/test")
      end
    end

    context "when skip_auth is not nil" do
      it "does not authorize before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to_not receive(:authorize!)

        client.http_get("/test", :skip_auth)
      end
    end

    it "calls Vra::Http.execute" do
      response   = double("response")
      path       = "/test"
      full_url   = "https://vra.corp.local/test"
      headers    = { "Accept" => "application/json", "Content-Type" => "application/json" }
      verify_ssl = true

      allow(client).to receive(:authorize!)
      expect(Vra::Http).to receive(:execute)
        .with(method: :get,
              url: full_url,
              headers: headers,
              verify_ssl: verify_ssl)
        .and_return(response)

      client.http_get(path)
    end

    it "raises an HTTPNotFound on a 404 error" do
      allow(client).to receive(:authorize!)
      allow(Vra::Http).to receive(:execute)
        .and_raise(Vra::Http::Error.new("message", 404, "Not Found"))

      expect { client.http_get("/404") }.to raise_error(Vra::Exception::HTTPNotFound)
    end
  end

  describe "#http_get_paginated_array!" do
    it "allows a limit override" do
      client.page_size = 10
      expect(client).to receive(:get_parsed)
        .with("/test?$top=10&$skip=0")
        .and_return("content" => [], "totalPages" => 1)

      client.http_get_paginated_array!("/test")
    end

    it "only calls get_parsed once when total pages is 0 (no items)" do
      expect(client).to receive(:get_parsed)
        .once
        .with("/test?$top=20&$skip=0")
        .and_return("content" => [], "totalPages" => 0)

      client.http_get_paginated_array!("/test")
    end

    it "only calls get_parsed once when total pages is 1" do
      expect(client).to receive(:get_parsed)
        .once
        .with("/test?$top=20&$skip=0")
        .and_return("content" => [], "totalPages" => 1)

      client.http_get_paginated_array!("/test")
    end

    it "calls get_parsed 3 times if there are 3 pages of response" do
      expect(client).to receive(:get_parsed)
        .with("/test?$top=20&$skip=0")
        .and_return("content" => [], "totalPages" => 3)
      expect(client).to receive(:get_parsed)
        .with("/test?$top=20&$skip=20")
        .and_return("content" => [], "totalPages" => 3)
      expect(client).to receive(:get_parsed)
        .with("/test?$top=20&$skip=40")
        .and_return("content" => [], "totalPages" => 3)

      client.http_get_paginated_array!("/test")
    end

    it "raises an exception if duplicate items are returned by the API" do
      allow(client).to receive(:get_parsed)
        .with("/test?$top=20&$skip=0")
        .and_return("content" => [1, 2, 3, 1], "totalPages" => 1)

      expect { client.http_get_paginated_array!("/test") }.to raise_error(Vra::Exception::DuplicateItemsDetected)
    end
  end

  describe "#http_post" do
    context "when skip_auth is nil" do
      it "authorizes before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to receive(:authorize!)

        client.http_post("/test", "some payload")
      end
    end

    context "when skip_auth is not nil" do
      it "does not authorize before proceeding" do
        response = double("response")
        allow(Vra::Http).to receive(:execute).and_return(response)
        expect(client).to_not receive(:authorize!)

        client.http_post("/test", "some payload", :skip_auth)
      end
    end

    it "calls Vra::Http.execute" do
      response   = double("response")
      path       = "/test"
      full_url   = "https://vra.corp.local/test"
      headers    = { "Accept" => "application/json", "Content-Type" => "application/json" }
      payload    = "some payload"
      verify_ssl = true

      allow(client).to receive(:authorize!)
      expect(Vra::Http).to receive(:execute)
        .with(method: :post,
              url: full_url,
              headers: headers,
              payload: payload,
              verify_ssl: verify_ssl)
        .and_return(response)

      client.http_post(path, payload)
    end

    context "when not verifying ssl" do
      let(:unverified_client) do
        Vra::Client.new(username: "user@corp.local",
                        password: "password",
                        domain: "domain",
                        base_url: "https://vra.corp.local",
                        verify_ssl: false)
      end

      before(:each) do
        allow(unverified_client).to receive(:authorized?).and_return(true)
      end

      it "configures Net::HTTP with VERIFY_NONE" do
        allow(Net::HTTP).to receive(:start).and_wrap_original do |_http, *args|
          expect(args.last).to include(verify_mode: OpenSSL::SSL::VERIFY_NONE)
          double("response", final?: true, success?: true)
        end

        unverified_client.http_post("/path", "payload")

        %i{head get}.each do |method|
          unverified_client.http_fetch(method, "/test", true)
        end
      end
    end

    it "calls raise_http_exception upon error" do
      allow(client).to receive(:authorize!)
      allow(Vra::Http).to receive(:execute).and_raise(StandardError)
      expect(client).to receive(:raise_http_exception)

      client.http_post("/404", "test payload")
    end
  end

  describe "#http_post!" do
    it "returns the response body" do
      response = double("response", body: "body text")
      allow(client).to receive(:http_post).with("/test", "test payload").and_return(response)

      expect(client.http_post!("/test", "test payload")).to eq "body text"
    end
  end

  describe "#http_delete" do
    it "should perform the delete method" do
      allow(client).to receive(:authorized?).and_return(true)
      expect(Vra::Http).to receive(:execute)

      client.http_delete("/test")
    end
  end

  describe "#raise_http_exception" do
    context "when a 404 is received" do
      let(:exception) do
        double("RestClient::ResourceNotFound",
               http_code: 404,
               message: "Not Found",
               response: "404 Not Found")
      end

      it "raises a Vra::Exception::HTTPNotFound exception" do
        expect { client.raise_http_exception(exception, "/test") }.to raise_error(Vra::Exception::HTTPNotFound)
      end
    end

    context "when an unspecified http error is received" do
      let(:exception) do
        double("RestClient::BadRequest",
               http_code: 400,
               message: "Bad Request",
               response: "400 Bad Request")
      end

      it "raises a Vra::Exception::HTTPError exception" do
        expect { client.raise_http_exception(exception, "/test") }.to raise_error(Vra::Exception::HTTPError)
      end
    end
  end

  describe "#validate_client_options!" do
    context "when all required options are supplied" do
      it "does not raise an exception" do
        expect { client.validate_client_options! }.not_to raise_error
      end
    end

    context "when username is missing" do
      let(:client) do
        described_class.new(
          password: "password",
          domain: "domain",
          base_url: "https://vra.corp.local"
        )
      end

      it "raises an exception" do
        expect { client.validate_client_options! }.to raise_error(ArgumentError)
      end
    end

    context "when password is missing" do
      let(:client) do
        described_class.new(
          username: "username",
          domain: "domain",
          base_url: "https://vra.corp.local"
        )
      end

      it "raises an exception" do
        expect { client.validate_client_options! }.to raise_error(ArgumentError)
      end
    end

    context "when domain is missing" do
      let(:client) do
        described_class.new(
          username: "username",
          password: "password",
          base_url: "https://vra.corp.local"
        )
      end

      it "raises an exception" do
        expect { client.validate_client_options! }.to raise_error(ArgumentError)
      end
    end

    context "when base URL is missing" do
      let(:client) do
        described_class.new(
          username: "username",
          password: "password",
          domain: "domain"
        )
      end

      it "raises an exception" do
        expect { client.validate_client_options! }.to raise_error(ArgumentError)
      end
    end

    context "when base URL is not a valid HTTP URL" do
      let(:client) do
        described_class.new(
          username: "username",
          password: "password",
          domain: "domain",
          base_url: "something-that-is-not-a-HTTP-URI"
        )
      end

      it "raises an exception" do
        expect { client.validate_client_options! }.to raise_error(ArgumentError)
      end

      it "should raise an exception when the URI::InvalidURIError is raised" do
        allow(URI).to receive(:parse).and_raise(URI::InvalidURIError)

        expect { client.validate_client_options! }
          .to raise_error(ArgumentError)
          .with_message("Base URL something-that-is-not-a-HTTP-URI is not a valid URI.")
      end
    end
  end
end
