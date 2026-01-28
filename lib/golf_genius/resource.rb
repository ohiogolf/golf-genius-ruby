# frozen_string_literal: true

module GolfGenius
  class Resource < GolfGeniusObject
    def self.resource_path
      # Convert class name to path
      # e.g., GolfGenius::Season -> "/seasons"
      name = self.name.split("::").last
      "/#{name.downcase}s"
    end

    def self.construct_from(attributes)
      new(attributes)
    end

    def refresh
      response = Request.execute(
        method: :get,
        path: "#{self.class.resource_path}/#{id}"
      )

      @attributes = Util.symbolize_keys(response)
      self
    end
  end
end
