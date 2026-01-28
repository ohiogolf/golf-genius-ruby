# frozen_string_literal: true

module GolfGenius
  module APIOperations
    module List
      def list(params = {}, opts = {})
        api_key = opts[:api_key]
        path = resource_path

        response = Request.execute(
          method: :get,
          path: path,
          params: params,
          api_key: api_key
        )

        # Response should be an array
        data = response.is_a?(Array) ? response : response["data"] || response

        data.map { |item| construct_from(item) }
      end
    end
  end
end
