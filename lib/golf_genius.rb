# frozen_string_literal: true

require "cgi"

require "golf_genius/version"
require "golf_genius/configuration"
require "golf_genius/errors"
require "golf_genius/util"

require "golf_genius/api_operations/request"
require "golf_genius/api_operations/list"
require "golf_genius/api_operations/retrieve"

require "golf_genius/resource"
require "golf_genius/client"

require "golf_genius/resources/season"
require "golf_genius/resources/category"
require "golf_genius/resources/directory"
require "golf_genius/resources/event"

module GolfGenius
end
