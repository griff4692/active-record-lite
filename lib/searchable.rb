require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)

    where_clause = params.keys.map do |attr_name|
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

    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
