require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
        1
    SQL

    sym_arr = result.first.map do |arr|
      arr.to_sym
    end
    sym_arr
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}") do
        @attributes[col.to_sym]
      end
      define_method("#{col}=") do |new_value|
        @attributes[col.to_sym] = new_value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    [].tap do |arr|
      results.each do |r|
        arr << new(r)
      end
    end
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
    parse_all(result).first
  end

  def initialize(params = {})
    @attributes ||= {}
    params.keys.each do |key|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      @attributes[key.to_sym] = params[key]
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    _, insert_string, insert_values = self.class.build_strings(@attributes)

    DBConnection.execute(<<-SQL, **attributes)
      INSERT INTO
        #{self.class.table_name}(#{insert_string})
      VALUES
        (#{insert_values})
    SQL

    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set_string, _, _ = self.class.build_strings(@attributes)

    DBConnection.execute(<<-SQL, **attributes)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_string}
      WHERE
        id = :id
    SQL
  end

  def save
    attributes[:id] ? update : insert
  end

  private
  def self.build_strings(opts)
    return_string_keys = ""
    insert_values = ""
    return_string = ""
    opts.keys.each_with_index do |key, index|
      next if key == :id
      return_string_keys += "#{key}"
      insert_values += ":#{key}"
      return_string += "#{key} = :#{key}"
      if (index + 1) < opts.keys.length
        return_string_keys += ', '
        return_string += ', '
        insert_values += ', '
      end
    end
    return return_string, return_string_keys, insert_values
  end
end
