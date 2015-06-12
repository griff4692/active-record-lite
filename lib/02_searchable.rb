require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    where_clause = params.map do |attr_name, attr_value|
      "#{attr_name} = ?"
    end.join(' AND ')

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_clause}
    SQL

    results.empty? ? [] : parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
