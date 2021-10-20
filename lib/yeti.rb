require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/indifferent_access"
require "active_model"
require "string_cleaner"
require "yeti/context"
require "yeti/errors"
require "yeti/viewer"
require "yeti/editor"
require "yeti/search"
require "yeti/version"

module Yeti
  def self.register_type(type_name, klass = nil, **options, &block)
    ::ActiveModel::Type.register(type_name, klass, **options, &block)
  end
end
