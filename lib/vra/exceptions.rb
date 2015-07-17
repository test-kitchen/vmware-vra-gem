module Vra
  module Exception
    class NotFound < RuntimeError; end
    class RequestError < RuntimeError; end
    class Unauthorized < RuntimeError; end

    class HTTPError < RuntimeError
      attr_accessor :klass, :code, :body, :errors, :path
      def initialize(opts={})
        @code = opts[:code]
        @body = opts[:body]
        @path = opts[:path]
        @klass = opts[:klass]
        @errors = []

        parse_errors
      end

      def parse_errors
        begin
          data = JSON.load(@body)
        rescue JSON::ParserError
          return
        end

        return if data.nil?
        return unless data['errors'].respond_to?(:each)

        data['errors'].each do |error|
          @errors << error['systemMessage']
        end
      end
    end

    class HTTPNotFound < HTTPError; end
  end
end
