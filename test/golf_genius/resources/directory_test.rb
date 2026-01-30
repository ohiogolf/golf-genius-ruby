# frozen_string_literal: true

require "test_helper"

class DirectoryTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_directories
    stub_api_request(method: :get, path: "/directories", response_body: DIRECTORIES, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/directories", response_body: [], query: { "page" => "2" })

    directories = GolfGenius::Directory.list

    assert_kind_of Array, directories
    assert_equal 2, directories.length
    assert_kind_of GolfGenius::Directory, directories.first
    assert_equal "dir_001", directories.first.id
    assert_equal "Main Directory", directories.first.name
  end

  def test_fetch_directory
    stub_api_request(method: :get, path: "/directories", response_body: DIRECTORIES, query: { "page" => "1" })

    directory = GolfGenius::Directory.fetch("dir_001")

    assert_kind_of GolfGenius::Directory, directory
    assert_equal "dir_001", directory.id
    assert_equal "Main Directory", directory.name
    assert_equal 25, directory.event_count
  end

  def test_directory_attributes
    directory = GolfGenius::Directory.construct_from(DIRECTORY)

    assert_equal "dir_001", directory.id
    assert_equal "Main Directory", directory.name
    assert_equal 25, directory.event_count
    assert_equal false, directory.all_events
  end

  def test_directory_events
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: EVENTS,
      query: { "directory" => "dir_001", "page" => "1" }
    )
    stub_api_request(
      method: :get,
      path: "/events",
      response_body: [],
      query: { "directory" => "dir_001", "page" => "2" }
    )

    directory = GolfGenius::Directory.construct_from(DIRECTORY)
    events = directory.events

    assert_kind_of Array, events
    assert_equal 2, events.length
    assert_kind_of GolfGenius::Event, events.first
    assert_equal "event_001", events.first.id
  end
end
