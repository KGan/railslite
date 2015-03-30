require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params) #extended, so we're in class
    #construct the 'where' parameters
    query = ""
    params.keys.each_with_index do |key, index|
      query += "#{key} = :#{key}"
      if (index + 1) < params.keys.length
        query += ' AND '
      end
    end

    results = DBConnection.execute(<<-SQL, params)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{query}
    SQL

    results.map { |result| new(result) }
  end
end

class SQLObject
  extend Searchable
end
