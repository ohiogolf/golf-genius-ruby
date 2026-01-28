# frozen_string_literal: true

module GolfGenius
  class Category < Resource
    extend APIOperations::List
    extend APIOperations::Retrieve

    def self.resource_path
      "/categories"
    end
  end
end
