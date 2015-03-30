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
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    opts = {
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id,
      class_name: "#{name.to_s.capitalize.singularize}"
    }.merge(options)

    @foreign_key = opts[:foreign_key]
    @primary_key = opts[:primary_key]
    @class_name = opts[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    opts = {
      foreign_key: "#{self_class_name.foreign_key}".to_sym,
      primary_key: :id,
      class_name: "#{name.to_s.capitalize.singularize}"
    }.merge(options)

    @foreign_key = opts[:foreign_key]
    @primary_key = opts[:primary_key]
    @class_name = opts[:class_name]
  end
end

module Associatable
  # Primary key is NOT ours, it is in the MODEL_CLASS we are retrieving.
  def belongs_to(name, options = {})
    bto = BelongsToOptions.new(name, options)

    define_method("#{name}") do
      value = send(bto.foreign_key)
      result = bto.model_class.where(bto.primary_key => value)
      result.first
    end

    assoc_options[name] = bto
  end

  def has_many(name, options = {})
    #primary key IS ours, MODEL_CLASS has the FOREIGN KEY we must match
    hmo = HasManyOptions.new(name, self.to_s, options)

    define_method("#{name}") do
      value = send(hmo.primary_key)
      hmo.model_class.where(hmo.foreign_key => value)
    end

    assoc_options[name] = hmo
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end

  def assoc_options_o
    @assoc_options_o ||= {}
  end
end

class SQLObject
  extend Associatable
end
