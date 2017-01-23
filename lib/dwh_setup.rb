require 'thor'
require 'pg'
require 'sequel'
require 'bigdecimal'
# require 'datetime'


class DwhSetup < Thor

  include ClassFactory
  DB ||= SequelConnector.new(Rails.env).connect_database
  # @conn ||= PG.connect( dbname: "dwh_#{Rails.env}")
  # DB = Sequel.postgres

  desc "create dimensions", "create Dimension Tables"
  def create_dimensions(*model_name)
    model_name.each do |mn|
      DB.create_table mn.downcase.pluralize.to_sym do
        all_attribs = mn.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }
        # raise all_attribs.inspect
        all_attribs.each do |attr|
          if attr[0].eql? 'id'
            primary_key attr[0]
          #   dimensions are better denormalized, so foreign_keys are best reduced
          elsif attr[0].ends_with? "_id"
            foreign_key attr[0], attr[2].downcase.to_sym
          else
            if attr[1].eql? 'datetime'
              DateTime attr[0]
            elsif attr[1].eql? 'string'
              String attr[0]
            elsif attr[1].eql? 'integer'
              Integer attr[0]
            elsif attr[1].eql? 'decimal'
              Decimal attr[0]
            end
          end
        end
      end
    end
  end

  desc "create fact", "create Fact Table"
  def create_fact(model_name)
    all_attribs = model_name.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }
    DB.create_table model_name.downcase.to_sym do
      all_attribs.each do |attr|
        if attr[0].eql? 'id'
          primary_key attr[0]
        elsif attr[0].ends_with? "_id"
          foreign_key attr[0], attr[2].downcase.pluralize.to_sym
        else
          if attr[1].eql? 'datetime'
            DateTime attr[0]
          elsif attr[1].eql? 'string'
            String attr[0]
          elsif attr[1].eql? 'integer'
            Integer attr[0]
          elsif attr[1].eql? 'decimal'
            Decimal attr[0]
          end
        end
      end
    end
  end

  desc "drop table", "drop a table"
  def drop_table(*model_name)
    model_name.each do |mn|
      DB.drop_table mn.downcase.pluralize.to_sym
    end
  end

  desc "add attribute to table", "add model attributes"
  def add_attribs(options={})
    DB.exec_prepared
  end

  desc "get data", "return model data"
  def get_data(model_name)
    DB[model_name].all#( "SELECT * FROM #{self}")
  end

  desc "disconnect", "Disconnect backend connection"
  def db_disconnect
    DB.close
  end
end