# frozen_string_literal: true

require "test_helper"

class CategoryTest < Minitest::Test
  def setup
    setup_test_configuration
  end

  def teardown
    GolfGenius.reset_configuration!
  end

  def test_list_categories
    stub_api_request(method: :get, path: "/categories", response_body: CATEGORIES, query: { "page" => "1" })
    stub_api_request(method: :get, path: "/categories", response_body: [], query: { "page" => "2" })

    categories = GolfGenius::Category.list

    assert_kind_of Array, categories
    assert_equal 2, categories.length
    assert_kind_of GolfGenius::Category, categories.first
    assert_equal "cat_001", categories.first.id
    assert_equal "Member Events", categories.first.name
  end

  def test_fetch_category
    stub_fetch("/categories", "cat_001", CATEGORY)

    category = GolfGenius::Category.fetch("cat_001")

    assert_kind_of GolfGenius::Category, category
    assert_equal "cat_001", category.id
    assert_equal "Member Events", category.name
    assert_equal "#FF5733", category.color
    assert_equal 15, category.event_count
  end

  def test_category_attributes
    category = GolfGenius::Category.construct_from(CATEGORY)

    assert_equal "cat_001", category.id
    assert_equal "Member Events", category.name
    assert_equal "#FF5733", category.color
    assert_equal 15, category.event_count
    assert_equal false, category.archived
  end
end
