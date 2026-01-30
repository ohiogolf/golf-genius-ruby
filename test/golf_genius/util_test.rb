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

  def test_date_attributes_parsed_as_time
    obj = GolfGenius::GolfGeniusObject.construct_from(
      {
        "id" => "m1",
        "created_at" => "2017-08-03 10:15:18 -0400",
        "updated_at" => "2017-08-15 14:39:31 -0400",
        "date" => "2026-04-15",
      }
    )

    assert_kind_of Time, obj.created_at
    assert_kind_of Time, obj.updated_at
    assert_kind_of Time, obj.date
    assert_equal 2017, obj.created_at.year
    assert_equal 8, obj.created_at.month
    assert_equal 3, obj.created_at.day
    assert_equal "2026-04-15", obj.date.strftime("%Y-%m-%d")
  end

  def test_to_h_serializes_time_as_iso8601
    obj = GolfGenius::GolfGeniusObject.construct_from(
      {
        "id" => "m1",
        "created_at" => "2017-08-03 10:15:18 -0400",
      }
    )

    hash = obj.to_h

    assert_kind_of String, hash[:created_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, hash[:created_at])
  end

  def test_boolean_predicate_methods
    obj = GolfGenius::GolfGeniusObject.construct_from(
      {
        "id" => "e1",
        "deleted" => false,
        "archived" => true,
        "waitlist" => false,
      }
    )

    assert_equal false, obj.deleted?
    assert_equal true, obj.archived?
    assert_equal false, obj.waitlist?
    assert_predicate obj, :archived?
    refute_predicate obj, :deleted?
  end

  def test_predicate_responds_to_missing
    obj = GolfGenius::GolfGeniusObject.construct_from({ "deleted" => false })

    assert_respond_to obj, :deleted?
  end
end
