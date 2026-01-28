# frozen_string_literal: true

module GolfGenius
  class Event < Resource
    extend APIOperations::List
    extend APIOperations::Retrieve

    # Get the roster for an event
    # GET /api_v2/{api_key}/events/{event_id}/roster
    def self.roster(event_id, params = {}, opts = {})
      api_key = opts[:api_key]
      path = "#{resource_path}/#{event_id}/roster"

      response = Request.execute(
        method: :get,
        path: path,
        params: params,
        api_key: api_key
      )

      # Response should be an array of roster entries
      data = response.is_a?(Array) ? response : response["data"] || response
      data.map { |item| GolfGeniusObject.construct_from(item) }
    end

    # Get the rounds for an event
    # GET /api_v2/{api_key}/events/{event_id}/rounds
    def self.rounds(event_id, params = {}, opts = {})
      api_key = opts[:api_key]
      path = "#{resource_path}/#{event_id}/rounds"

      response = Request.execute(
        method: :get,
        path: path,
        params: params,
        api_key: api_key
      )

      data = response.is_a?(Array) ? response : response["data"] || response
      data.map { |item| GolfGeniusObject.construct_from(item) }
    end

    # Get the courses/tees for an event
    # GET /api_v2/{api_key}/events/{event_id}/courses
    def self.courses(event_id, params = {}, opts = {})
      api_key = opts[:api_key]
      path = "#{resource_path}/#{event_id}/courses"

      response = Request.execute(
        method: :get,
        path: path,
        params: params,
        api_key: api_key
      )

      data = response.is_a?(Array) ? response : response["data"] || response
      data.map { |item| GolfGeniusObject.construct_from(item) }
    end

    # Get tournaments for a specific round
    # GET /api_v2/{api_key}/events/{event_id}/rounds/{round_id}/tournaments
    def self.tournaments(event_id, round_id, params = {}, opts = {})
      api_key = opts[:api_key]
      path = "#{resource_path}/#{event_id}/rounds/#{round_id}/tournaments"

      response = Request.execute(
        method: :get,
        path: path,
        params: params,
        api_key: api_key
      )

      data = response.is_a?(Array) ? response : response["data"] || response
      data.map { |item| GolfGeniusObject.construct_from(item) }
    end
  end
end
