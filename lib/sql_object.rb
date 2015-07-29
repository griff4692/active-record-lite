require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'

# inspired by ActiveRecord::Base
class SQLObject
  # factory methods
  def self.columns
    return @columns if @columns
    # returns all column names
    cols = DBConnection.execute2(<<-SQL).first
      SELECT
        #{table_name}.*
      FROM
        #{self.table_name}
    SQL
    cols.map!(&:to_sym)
    @columns = cols
  end

  def self.finalize!
    columns.each do |attr_name|
      define_method(attr_name) do
        self.attributes[attr_name]
      end

      define_method("#{attr_name}=") do |attr_value|
        self.attributes[attr_name] = attr_value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    # can overwrite table name ||or allow ActiveSupport to infer it
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
  SELECT
    #{table_name}.*
  FROM
    #{table_name}
  WHERE
    #{table_name}.id = ?
    SQL

    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
          raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    cols = self.class.columns.drop(1) # dont include id
    question_marks = (["?"] * cols.count).join(', ')
    col_names = cols.map(&:to_s).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
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
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
