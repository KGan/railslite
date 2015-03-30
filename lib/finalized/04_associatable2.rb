require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method("#{name}") do
      # bt: model_class : intermediate, foreign = own key, primary = intermediate key
      bt_opts = self.class.assoc_options[through_name]
      # next: model_class : final, foreign = intermediate key, primary = final key
      next_opts = bt_opts.model_class.assoc_options[source_name]
      my_key = bt_opts.primary_key
      inter_key = next_opts.foreign_key
      final_key = next_opts.primary_key
      final_table = next_opts.table_name
      inter_table = bt_opts.table_name

      result = DBConnection.execute(<<-SQL, val: send(my_key))
        SELECT
          #{final_table}.*
        FROM
          #{final_table}
        JOIN
          #{inter_table} ON #{inter_table}.#{inter_key} = #{final_table}.#{final_key}
        WHERE
          #{inter_table}.#{my_key} = :val
      SQL

      next_opts.model_class.parse_all(result).first
    end
  end

  def has_many_through(name, through_name, source_name)
    define_method("#{name}") do
      # bt: model_class : intermediate, foreign = own key, primary = intermediate key
      if self.class.assoc_options.has_key?(through_name)
        bt_opts = self.class.assoc_options[through_name]
      elsif self.class.assoc_options_o.has_key?(through_name)
        bt_opts = self.class.assoc_options_o[through_name]
        fj = true
      end
      # next: model_class : final, foreign = intermediate key, primary = final key
      if bt_opts.model_class.assoc_options.has_key?(source_name)
        next_opts = bt_opts.model_class.assoc_options[source_name]
      else
        next_opts = bt_opts.model_class.assoc_options_o[source_name]
        sj = true
      end

      if fj
        my_key = bt_opts.foreign_key
      else
        my_key = bt_opts.primary_key
      end

      if sj
        inter_key = next_opts.primary_key
        final_key = next_opts.
      else
        inter_key = next_opts.foreign_key
        final_key = next_opts.primary_key
      end


      final_table = next_opts.table_name
      inter_table = bt_opts.table_name

      result = DBConnection.execute(<<-SQL, val: send(my_key))
        SELECT
          #{final_table}.*
        FROM
          #{final_table}
        JOIN
          #{inter_table} ON #{inter_table}.#{inter_key} = #{final_table}.#{final_key}
        WHERE
          #{inter_table}.#{my_key} = :val
      SQL

      next_opts.model_class.parse_all(result)
    end
  end
end
