require 'thor'
require 'pg'
require 'sequel'
require 'bigdecimal'
require 'active_record'
# require 'datetime'


class DwhSetup < Thor

  def initialize
    @db ||= SequelConnector.new(Rails.env).connect_database
    # @conn ||= PG.connect( dbname: "dwh_#{Rails.env}")
    @conn ||= PG.connect( dbname: "walmart_dev")
    @ar_conn ||= ActiveRecord::Base.connection

    # DB = Sequel.postgres
  end

  desc "create dimensions", "create Dimension Tables. Accepts array of model names"
  def create_dimensions_old(model_name)
    model_name.each do |mn|
      # next if DB.table_exists?(mn.downcase.pluralize.to_sym)
      @db.create_table? mn.downcase.pluralize.to_sym do
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

  desc "create dimensions", "create Dimension Tables. Accepts array of model names and model attributes"
  def create_dimensions(opts = {})
    # raise opts['attribs'].inspect
    tables_created = []
    opts['dimensions'].each_with_index do |tab,idx|
      table_name = tab.downcase.pluralize + "-#{opts['id']}"
      table_attribs = tab.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }
      wanted_attribs = opts['attribs'][tab].select{ |att| att if att.split('-')[0].downcase.to_sym == tab.downcase.to_sym }
      if wanted_attribs.any?
        local_fields = wanted_attribs.map{ |wa| wa.split('-')}.map{ |res| res[1]}

        applicable_attribs = table_attribs.select{ |att| att.flatten if local_fields.include?att[0].gsub('_','')}
        # applicable_attribs.push()

        @ar_conn ||= ActiveRecord::Base.connection
        if @ar_conn.create_table(table_name.to_sym)
          tables_created.push(table_name)
        end

        applicable_attribs.each do |attrib|
          fd = attrib
          next if fd[0].eql? 'id'
          @ar_conn.add_column( table_name.to_sym, fd[0].to_sym, fd[1].to_sym)

        end
      end

    #   handle foreign values
      foreign_attribs = opts['attribs'][tab].select{ |att| att if att.split('-')[0].downcase.to_sym != tab.downcase.to_sym }
      if foreign_attribs.any?
        foreign_tabs = foreign_attribs.map{ |fa| fa.split('-')}
        foreign_tables = foreign_tabs.map(&:first).uniq

        tables_attributes = foreign_tables.map { |r| [r, foreign_tabs.map{|s| s[1] if s[0].eql?r }.compact] }
        # raise tables_attributes.inspect
        tables_attributes.each do |tab|
          table_name = tab[0].downcase.pluralize + "-#{opts['id']}"
          table_attribs = tab[0].classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }

          applicable_attribs = table_attribs.select{ |att| att.flatten if tab[1].include?att[0].gsub('_','')}

          @ar_conn ||= ActiveRecord::Base.connection
          if @ar_conn.create_table(table_name.to_sym)
            tables_created.push(table_name)
          end
          applicable_attribs.each do |attrib|
            fd = attrib.flatten
            next if fd[0].eql? 'id'
            @ar_conn.add_column( table_name.to_sym, fd[0].to_sym, fd[1].to_sym)

          end
        end
      end
    end
    self.populate_blank(tables_created)
  end

  desc "populator", "populates blank table with data. Takes array of table names"
  def populate_blank(table_names)
    table_names.each do |table_name|
      model_name = table_name.split('-')
      my_attribs = get_attributes(table_name).rows.flatten
      # raise my_attribs.inspect

      data = model_name[0].classify.constantize.pluck(my_attribs.join(','))
      @ar_conn ||= ActiveRecord::Base.connection
      @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{my_attribs.join(',')} FROM #{model_name[0]};")
    end
  end

  desc "update_dependents", "updates dependent tables with data from master table"
  def updator(table_names,last_time)
    query_data = table_names[0].classify.constantize.where(updated_at: (last_time..Time.current ) )
    table_names.each do |tab|
      next if tab.eql?table_names[0]
      my_attribs = get_attributes(tab).rows.flatten

      # applicable_data = query_data.select(my_attribs.join(','))
      applicable_data = query_data.select(my_attribs.join(','))
      # my_model = model_name.classify.constantize
      # all_attribs =  my_model.columns.map{|x| x.name.to_sym }
      # data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))

      query_coll = applicable_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}
      # my_keys = data.attributes.keys
      # my_values = data.attributes.values
      query_coll.each do |qc|
        @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
      end

    end

  end

  desc "create fact", "create Fact Table. Accepts string table_name"
  def create_fact(model_name)

    @db.create_table? model_name.downcase.pluralize.to_sym do
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


  desc "get table attributes", "returns a list of table attributes"
  def get_attributes(model_name)
    @ar_conn ||= ActiveRecord::Base.connection
    @ar_conn.exec_query("SELECT column_name FROM information_schema.columns WHERE table_name = " + " '#{model_name}'  " )

  end

  desc "drop table", "drop a table"
  def drop_table(*model_name)
    model_name.each do |mn|
      @db.drop_table mn.downcase.pluralize.to_sym
    end
  end

  desc "add attribute to table", "add model attributes"
  def add_attribs(options={})
    @db.exec_prepared
  end

  desc "get data", "return model data"
  def get_data(model_name)
    @db[model_name].all#( "SELECT * FROM #{self}")
  end

  desc "disconnect", "Disconnect backend connection"
  def db_disconnect
    @db.close
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
    @db[model_name.pluralize.downcase.to_sym].import(all_attribs, data )
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
      @db[model_name.pluralize.downcase.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
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
    @db[model_name.pluralize.downcase.to_sym].insert_conflict(:target=>:id, :update=>my_keys.zip(my_values).to_h).insert(data.attributes)
  end

  desc "insert into table", "insert new record"
  def insert(model_name,record_id)
    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  my_model.find(record_id)
    @db[model_name.pluralize.downcase.to_sym].insert(data.attributes)
  end

  desc "delete record", "delete record from table"
  def delete(model_name,record_id)
    @db[model_name.pluralize.downcase.to_sym].filter(:id => record_id).delete
  end

  desc "convert ar_object", "private method to extract values of ActiveRecord  Object"
  def convert(ar_object)
    data_collection = []
    ar_object.each {|ar| data_collection.push(ar.attributes.values)}
    data_collection
  end
end