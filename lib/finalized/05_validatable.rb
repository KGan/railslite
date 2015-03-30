require_relative '04_associatable2'

module Validatable
  def validates(column, **options)
    presence = options[:presence]
    unique = !!options[:uniqueness]
    unique_scope = options[:uniqueness][:scope]
    if presence
      define_method("my_validate_#{column}_presence") do
        errors[:presence] << "column #{column} not present" unless attributes[column]
      end
      @validators << "#{column}_presence"
    end
    if unique
      if unique_scope
        define_method("my_validate_#{column}_uniqueness") do
          result = DBConnection.execute(<<-SQL)
            SELECT
              COUNT(*)
            FROM
              #{self.class.table_name}
            WHERE
              #{column} = #{attributes[column]}
          SQL
          if result.first > 0
            errors[:unique] << "column #{column} must be unique"
          end
        end
      else
        define_method("my_validate_#{column}_uniqueness") do
          #TODO
          result = DBConnection.execute(<<-SQL)
            SELECT
              COUNT(*)
            FROM
              #{self.class.table_name}
            WHERE
              #{column} = #{attributes[column]}
              AND
              #{unique_scope} = #{attributes[unique_scope]}
          SQL
          error_string = "column #{column} must be unique in scope of #{unique_scope}"
          errors[:unique] << error_string unless result.first < 1
        end
      end
      @validators << "#{column}_presence"
    end
  end

  def validate
    @validators.each do |val|
      send("my_validate_#{val}")
    end
    if errors.empty?
  end

  define_method('errors') do
    @errors ||= {}
  end

  define_method('valid?') do
    validate
    errors.empty?
  end

  validations :save, call: :validate

  def validators
    @validators ||= []
  end

end

module DoBefore
  def validations meth, opts
    old_method = instance_method(meth)
    define_method(meth) do
      send opts[:call]
      if errors.empty?
        old_method.bind(self).call
      else
        raise "failed validations:\n #{errors}"
      end
    end
  end
end

class SQLObject
  extend Validatable
  extend DoBefore
end
