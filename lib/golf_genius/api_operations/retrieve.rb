# frozen_string_literal: true

module GolfGenius
  module APIOperations
    module Retrieve
      def retrieve(id, params = {}, opts = {})
        api_key = opts[:api_key]
        path = "#{resource_path}/#{id}"

        response = Request.execute(
          method: :get,
          path: path,
          params: params,
          api_key: api_key
        )

        construct_from(response)
      end
    end
  end
end
