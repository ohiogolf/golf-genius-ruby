# frozen_string_literal: true

module GolfGenius
  class Directory < Resource
    extend APIOperations::List
    extend APIOperations::Retrieve

    def self.resource_path
      "/directories"
    end
  end
end
