require 'thor'
require 'pg'
require 'sequel'
require 'bigdecimal'
# require 'datetime'


class DwhSetup < Thor

  DB ||= SequelConnector.new(Rails.env).connect_database
  # @conn ||= PG.connect( dbname: "dwh_#{Rails.env}")
  @conn ||= PG.connect( dbname: "walmart_#{Rails.env}")
  # DB = Sequel.postgres

  desc "create dimensions", "create Dimension Tables. Accepts array of model names"
  def create_dimensions(model_name)
    model_name.each do |mn|
      # next if DB.table_exists?(mn.downcase.pluralize.to_sym)
      DB.create_table? mn.downcase.pluralize.to_sym do
        all_attribs = mn.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }
        # raise all_attribs.inspect
        all_attribs.each do |attr|
          if attr[0].eql? 'id'
            primary_key attr[0]
            #   dimensions are better denormalized, so foreign_keys are best reduced
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
  end

  desc "create fact", "create Fact Table. Accepts string table_name"
  def create_fact(model_name)

    DB.create_table? model_name.downcase.pluralize.to_sym do
      all_attribs = model_name.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }
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

  desc "create table", "creates table relation. Accepts string table_name"
  def create_vtable(v_name, model_name, attribs)
    @conn.exec ( "CREATE TABLE #{v_name} AS
        SELECT  #{attribs.size.times { p '?' } }
        FROM #{model_name.size.times { p '?' } }
        WHERE
      "
    )
  rescue PG::Error => e
    puts e.message

  ensure
    @conn.close if conn




  end

  desc "get fact attributes", "returns a list of table attributes"
  def get_attributes(
      SELECT column_name
  FROM information_schema.columns
  WHERE table_name = ? )

    @conn.exec( )
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

  desc "extract_and_load", "copy bulk data from one data table to another. Accepts string"
  def extract_load(model_name,last_scan)
    # raise model_name.inspect
    # coll_str = []
    # coll_str.push model_name
    # check if table exists in destination
    # if create_dimensions(coll_str)
    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))
    # raise data.inspect
    DB[model_name.pluralize.downcase.to_sym].import(all_attribs, data )
    # end
  end

  desc "bulk insert_update table", "inserts into or updates table with batch record"
  def bulk_insert_update(model_name,last_scan)
    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))
    query_data = my_model.where(updated_at: (1.day.ago..Time.current ) )
    query_coll = query_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}
    # my_keys = data.attributes.keys
    # my_values = data.attributes.values
    query_coll.each do |qc|
      DB[model_name.pluralize.downcase.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
    end
    # DB[model_name.pluralize.downcase.to_sym].insert_conflict(:target=>:id, :update=>my_keys.zip(my_values).to_h).insert(data.attributes)
  end

  desc "insert_update table", "inserts into or updates table with record"
  def insert_update(model_name,record_id)
    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  my_model.find(record_id)
    my_keys = data.attributes.keys
    my_values = data.attributes.values
    DB[model_name.pluralize.downcase.to_sym].insert_conflict(:target=>:id, :update=>my_keys.zip(my_values).to_h).insert(data.attributes)
  end

  desc "insert into table", "insert new record"
  def insert(model_name,record_id)
    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  my_model.find(record_id)
    DB[model_name.pluralize.downcase.to_sym].insert(data.attributes)
  end

  desc "delete record", "delete record from table"
  def delete(model_name,record_id)
    DB[model_name.pluralize.downcase.to_sym].filter(:id => record_id).delete
  end

  desc "convert ar_object", "private method to extract values of ActiveRecord  Object"
  def convert(ar_object)
    data_collection = []
    ar_object.each {|ar| data_collection.push(ar.attributes.values)}
    data_collection
  end
end