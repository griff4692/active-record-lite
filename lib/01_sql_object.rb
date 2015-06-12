require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    .first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |attr_name|
      define_method(attr_name) do
        attributes[attr_name]
      end

      define_method("#{attr_name}=") do |attr_value|
        attributes[attr_name] = attr_value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    self_obj_array = []

    results.each do |result|
      self_obj_array << self.new(result)
    end

    self_obj_array
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
          raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attr_values = []
    self.class.columns.each do |attr_name|
      attr_values << self.send(attr_name)
    end
    attr_values
  end

  def insert
    q = (["?"] * self.class.columns.count).join(', ')
    cols = self.class.columns.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{cols})
      VALUES
        (#{q})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    to_set = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{to_set}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
