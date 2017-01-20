require 'thor'
require 'pg'


class DwhSetup < Thor

  include ClassFactory

  @conn ||= PG.connect( dbname: "dwh_#{Rails.env}")
  # @creator ||= ClassFactory::Chef

  desc "create dimensions", "create Dimension Tables"
  def create_dimensions(*model_name)
    model_name.each do |mn|
      create_class(mn)
      @conn.exec("CREATE #{mn} ()")
    end
  end

  desc "create fact", "create Fact Table"
  def create_fact(model_name)
    @creator.create_class(mn)
    @conn.exec("CREATE #{model_name} ()")
  end

  desc "drop table", "drop a table"
  def drop_table(*model_name)
    model_name.each do |mn|
      @conn.exec("DROP #{mn}")
    end
  end

  desc "add attribute to table", "add model attributes"
  def self.add_attribs(options={})
    @conn.exec_prepared
  end

  desc "get data", "return model data"
  def self.get_data
    @conn.exec( "SELECT * FROM #{self}")
  end

  # disconnect back-end connection
  def db_disconnect
    @conn.close
  end
end