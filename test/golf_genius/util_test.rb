# frozen_string_literal: true

require "test_helper"

class UtilTest < Minitest::Test
  def test_golf_genius_object_construct_from
    obj = GolfGenius::GolfGeniusObject.construct_from({ "id" => "123", "name" => "Test" })

    assert_equal "123", obj.id
    assert_equal "Test", obj.name
  end

  def test_golf_genius_object_nested_conversion
    data = { "id" => "e1", "season" => { "id" => "s1", "name" => "2026" } }
    obj = GolfGenius::GolfGeniusObject.construct_from(data)

    assert_equal "e1", obj.id
    assert_kind_of GolfGenius::GolfGeniusObject, obj.season
    assert_equal "s1", obj.season.id
    assert_equal "2026", obj.season.name
  end

  def test_golf_genius_object_key_and_bracket
    obj = GolfGenius::GolfGeniusObject.construct_from({ "id" => "123", "name" => "Test" })

    assert obj.key?(:id)
    assert obj.key?("id")
    refute obj.key?(:missing)
    assert_equal "123", obj[:id]
    assert_equal "Test", obj[:name]
  end

  def test_util_singularize_resource_key
    assert_equal "directory", GolfGenius::Util.singularize_resource_key("directories")
    assert_equal "season", GolfGenius::Util.singularize_resource_key("seasons")
    assert_equal "category", GolfGenius::Util.singularize_resource_key("categories")
    assert_equal "event", GolfGenius::Util.singularize_resource_key("events")
  end
end
