require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
        class_name: name.to_s.camelcase,
        foreign_key: name.to_s.concat("_id").to_sym,
        primary_key: :id
    }

    default = default.merge(options)

    @class_name = default[:class_name]
    @foreign_key = default[:foreign_key]
    @primary_key = default[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: self_class_name.downcase.concat("_id").to_sym,
      primary_key: :id
    }
    default = default.merge(options)
    @class_name = default[:class_name]
    @foreign_key = default[:foreign_key]
    @primary_key = default[:primary_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    assoc_options[name] = options

    define_method(name) do
      foreign_key = self.send(options.foreign_key)

      result = (options.model_class).where(options.primary_key => foreign_key)

      result.first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    results = define_method(name) do
      result = (options.model_class).where(options.foreign_key => self.id)
    end

    results
  end

  def assoc_options
    @assoc_options = @assoc_options || {}
  end
end

class SQLObject
  extend Associatable
end
