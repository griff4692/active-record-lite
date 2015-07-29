require_relative 'searchable'
require 'active_support/inflector'

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
    defaults = {
        class_name: name.to_s.camelcase,
        foreign_key: name.to_s.concat("_id").to_sym,
        primary_key: :id
    }

    defaults.merge(options).each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: self_class_name.downcase.concat("_id").to_sym,
      primary_key: :id
    }

    defaults.merge(options).each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

module Associatable
  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      foreign_key_val = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => foreign_key_val)
        .first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    results = define_method(name) do
      result = (options.model_class).where(options.foreign_key => self.id)
    end

    results
  end
end

class SQLObject
  extend Associatable
end
