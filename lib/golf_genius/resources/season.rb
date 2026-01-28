# frozen_string_literal: true

module GolfGenius
  class Season < Resource
    extend APIOperations::List
    extend APIOperations::Retrieve
  end
end
