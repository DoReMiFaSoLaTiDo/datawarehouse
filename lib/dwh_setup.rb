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

  end


  desc "create dimensions", "create Dimension Tables. Accepts array of model names and model attributes"
  def create_dimensions(opts = {})
    # raise opts['attribs'].inspect
    # single_tables = []
    # composed_tables = []

    my_tables = []
    opts['dimensions'].each do |tab|
      table_name = tab.downcase.pluralize + "-#{opts['id']}"
      table_attribs = tab.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }

      wanted_attribs = opts['attribs'][tab].select{ |att| att if att.split('-')[0].downcase.to_sym == tab.downcase.to_sym }
      foreign_attribs = opts['attribs'][tab].select{ |att| att if att.split('-')[0].downcase.to_sym != tab.downcase.to_sym }

      if wanted_attribs.any? || foreign_attribs.any?
        local_fields = wanted_attribs.map{ |wa| wa.split('-')}.map{ |res| res[1]}

        applicable_attribs = table_attribs.select{ |att| att.flatten if local_fields.include?att[0].gsub('_','')}
        # applicable_attribs.push()

        # my_attribs = []

        @ar_conn ||= ActiveRecord::Base.connection
        @ar_conn.create_table(table_name.to_sym)
        my_tables.push(table_name)

        applicable_attribs.each do |attrib|
          fd = attrib
          next if fd[0].eql? 'id'
          att = tab.downcase.pluralize + '_' + fd[0]

          @ar_conn.add_column( table_name.to_sym, att.to_sym, fd[1].to_sym)

        end

        #   handle foreign values
        if foreign_attribs.any?

          foreign_tabs = foreign_attribs.map{ |fa| fa.split('-')}
          foreign_tables = foreign_tabs.map(&:first).uniq

          tables_attributes = foreign_tables.map { |r| [r, foreign_tabs.map{|s| s[1] if s[0].eql?r }.compact] }
          # raise tables_attributes.inspect
          tables_attributes.each do |tab|

            table_attribs = tab[0].classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }

            fk_attribs = table_attribs.select{ |att| att.flatten if tab[1].include?att[0].gsub('_','')}

            @ar_conn ||= ActiveRecord::Base.connection
            fk_attribs.each do |attrib|
              fd = attrib.flatten
              # next if fd[0].eql? 'id'
              att = tab[0].downcase.pluralize + '_' + fd[0]
              @ar_conn.add_column( table_name.to_sym, att.to_sym, fd[1].to_sym)

            end
          end
        end
      end
    end
    # raise my_tables.inspect
    self.populate_tables(my_tables)
  end


  desc "updates tables in id", "updates all tables found in ID. Takes ID and last scan time"
  def update_tables(biz_id, last_time, prime_table =  "Biz")
    # @ar_conn ||= ActiveRecord::Base.connection
    bz = prime_table.classify.constantize.where(id: biz_id).pluck(:fact, :dimensions).flatten

    my_tables = bz.map{ |ez| ez.downcase.pluralize + '-' + biz_id.to_s}

    my_tables.each do |tab|
      master_table =  tab.split('-')[0]

      my_attribs = get_attributes(tab).rows.flatten
      data_attributes = my_attribs.map{ |att| att.sub('_','.')}

      #   check if table is composed
      data_attributes[0] = master_table + '.' + data_attributes[0] if data_attributes[0].eql?'id'
      my_tables = data_attributes.map{ |w| w.split(/[.\s]/) }.map{|da| da[0]}.uniq

      @ar_conn ||= ActiveRecord::Base.connection

      if my_tables.size == 1
        query_data = master_table.classify.constantize.where(updated_at: (last_time..Time.current ) )

        if query_data.present?

          applicable_data = query_data.select(data_attributes.join(','))
          data_relation = []
          applicable_data.each do |ad|
            arr = my_attribs.zip(ad.attributes.values)
            data_relation.push(arr.to_h)
          end

          query_coll = applicable_data.each {|qr| my_attribs.zip(qr.attributes.values).to_h}

          # raise data.inspect
          data_relation.each do |qc|
            @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc).insert(qc)
          end
        end

      else

        where_clause = []
        and_clause = []
        (1..my_tables.size-1).each do |num|
          qstr = my_tables[0] + '.' + my_tables[num].singularize + '_id' + ' = ' + my_tables[num] + '.' + 'id'
          where_clause.push(qstr)
        end

        where_clause = where_clause.join(' , ').gsub(' , ', ' AND ')


        and_clause.push("  #{my_tables[0]}" + '.' + "updated_at BETWEEN  " + "'"+"#{last_time}"+"'" + " AND " + "'"+"#{Time.current}"+"'")
        (1..my_tables.size-1).each do |num|
          and_clause.push(" OR #{my_tables[num]}" + '.' + "updated_at BETWEEN " + "'"+"#{last_time}"+"'" + " AND " + "'"+"#{Time.current}"+"'" )
        end
        and_clause = and_clause.join(' , ').gsub(' , ', ' ')
        # raise where_clause.inspect
        # data =  dtab.classify.constantize.joins(my_tables.map(&:singularize).map(&:to_sym).join(','))
        query_data = @ar_conn.exec_query(" SELECT #{data_attributes.join(',')} FROM #{my_tables.join(',')} WHERE #{where_clause} AND ( #{and_clause} );")

        if query_data.present?
          row_data = query_data.rows
          # applicable_data = query_data.select(data_attributes.join(','))

          data_relation = []
          row_data.each do |ad|
            arr = my_attribs.zip(ad)
            data_relation.push(arr.to_h)
          end


          data_relation.each do |qc|
            @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc).insert(qc)
          end
        end

      end
    end

  end



  desc "populate tables", "populates tables. Takes array of table names"
  def populate_tables(dim_tables)
    dim_tables.each do |dtab|
      table_name = dtab
      my_attribs = get_attributes(table_name).rows.flatten
      data_attributes = my_attribs.map{ |att| att.sub('_','.')}

    #   check if table is composed
      data_attributes[0] = dtab.split('-')[0] + '.' + data_attributes[0] if data_attributes[0].eql?'id'

      my_tables = data_attributes.map{ |w| w.split(/[.\s]/) }.map{|da| da[0]}.uniq


      @ar_conn ||= ActiveRecord::Base.connection
      if my_tables.size == 1
        @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{data_attributes.join(',')} FROM #{my_tables[0]};")

      else
        where_clause = []
        (1..my_tables.size-1).each do |num|
          qstr = my_tables[0] + '.' + my_tables[num].singularize + '_id' + ' = ' + my_tables[num] + '.' + 'id'
          where_clause.push(qstr)
        end

        where_clause = where_clause.join(' , ').gsub(' , ', ' AND ')
        # raise where_clause.inspect

        @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{data_attributes.join(',')} FROM #{my_tables.join(',')} WHERE #{where_clause};")
      end
    end

  end


  desc "single table populator", "populates tables that reflect master table 100%. Takes array of table name"
  def populate_singles(table_names)
    table_names.each do |table_name|

      model_name = table_name.split('-')
      my_attribs = get_attributes(table_name).rows.flatten

      data = model_name[0].classify.constantize.pluck(my_attribs.join(','))
      @ar_conn ||= ActiveRecord::Base.connection
      @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{my_attribs.join(',')} FROM #{model_name[0]};")
    end
  end

  desc "composed table populator", "populates table composed of data from 2 or more tables. Takes array of table name, connected tables, and attributes"
  def populate_composed(composed_table)
      table_name = composed_table[0]
      model_name = table_name.split('-')

      # my_attribs = composed_table[2].map{ |att| att.sub('_','.')}
      my_attribs = get_attributes(table_name).rows.flatten
      data_attributes = my_attribs.map{ |att| att.sub('_','.')}

      # raise composed_table.inspect
      data = model_name[0].classify.constantize.pluck(my_attribs.join(','))
      @ar_conn ||= ActiveRecord::Base.connection
      # @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{my_attribs.join(',')} FROM #{model_name[0]};")
      @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{data_attributes.flatten.join(',')} FROM #{composed_table[1].map(&:downcase).map(&:pluralize).join(', ')};")

  end


  desc "composed table populator", "populates table composed of data from 2 or more tables. Takes array of table name, connected tables, and attributes"
  def query_syntax(prime_table =  "Biz", last_time = 1970, biz_id)
    # @ar_conn ||= ActiveRecord::Base.connection
    bz = prime_table.classify.constantize.find(biz_id)

    bz.dimensions.each_with_index do |dim,idx |
      model_name = dim.downcase.pluralize+'-'+ biz_id.to_s
      my_measures = bz.measures[idx].split(',').map(&:strip)
      # raise my_measures.inspect
      tables_rep = my_measures.map{ |att| att.split('-')[0] }.uniq
      # raise tables_rep.inspect
      if tables_rep.size > 1
        query_attribs = []
        composed_table = []
        tables_rep.each do |tab|
          master_attribs = tab.classify.constantize.columns.map{|x| x.name }
          tab_attribs = my_measures.select{ |att| att if att.split('-')[0].downcase.to_sym == tab.downcase.to_sym }
          applicable_attribs = master_attribs.select{ |att| att.flatten if tab_attribs.include?att[0].gsub('_','')}
          query_string = applicable_attribs.map{ |aa| tab+'.'+aa }
          query_attribs.push(query_string)
        end

        composed_table[0] = model_name
        composed_table[1] = tables_rep
        composed_table[2] = query_attribs
        if last_time.eql? 1970
          self.populate_composed(composed_table)
        else
          self.update_composed(query_attribs, last_time)
        end


      else
        model_name = dim.downcase.pluralize+'-'+ biz_id.to_s
        if last_time.eql?1970
          self.populate_singles([model_name])
        else
          self.updator([model_name],last_time)
        end
      end

    end
    # raise bz.inspect
  end

  desc "dimension table populator", "populates blank table with data. Takes array of table names"
  def populate_blanks(table_names)
    table_names.each do |table_name|
      model_name = table_name.split('-')
      my_attribs = get_attributes(table_name).rows.flatten

      data = model_name[0].classify.constantize.pluck(my_attribs.join(','))
      @ar_conn ||= ActiveRecord::Base.connection
      @ar_conn.exec_query("INSERT INTO " + " \"#{table_name}\" " + " SELECT #{my_attribs.join(',')} FROM #{model_name[0]};")
    end
  end


  desc "create fact", "create fact table. Final"
  def create_fact(opts = {})

    my_tables = []
    tab = opts['fact']

    table_name = tab.downcase.pluralize + "-#{opts['id']}"
    table_attribs = tab.classify.constantize.columns.map{|x| [x.name, x.type.to_s, x.human_name] }

    @ar_conn ||= ActiveRecord::Base.connection
    @ar_conn.create_table(table_name.to_sym)
    my_tables.push(table_name)

    table_attribs.each do |attrib|
      fd = attrib
      next if fd[0].eql? 'id'
      att = tab.downcase.pluralize + '_' + fd[0]

      @ar_conn.add_column( table_name.to_sym, att.to_sym, fd[1].to_sym)

    end


    self.populate_tables(my_tables)

  end




  desc "update_dependents", "updates dependent tables with data from master table"
  def updator(table_names,last_time)
    table_names.each do |tab|
      master_table = tab.split('-')[0]

      query_data = master_table.classify.constantize.where(updated_at: (last_time..Time.current ) )

      if query_data.present?
        my_attribs = get_attributes(tab).rows.flatten
        applicable_data = query_data.select(my_attribs.join(','))

        query_coll = applicable_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}

        query_coll.each do |qc|
          @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
        end
      end
    end

  end


  desc "update_dependents", "updates dependent tables with data from master table"
  def updator_old(table_names,last_time)
    table_names.each do |tab|
      master_table = tab.split('-')[0]

      query_data = master_table.classify.constantize.where(updated_at: (last_time..Time.current ) )

      if query_data.present?
        my_attribs = get_attributes(tab).rows.flatten
        applicable_data = query_data.select(my_attribs.join(','))

        query_coll = applicable_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}

        query_coll.each do |qc|
          @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
        end
      end
    end

  end


  desc "update_dependents", "updates dependent tables with data from master table"
  def updator_old_old(table_names,last_time)
    query_data = table_names[0].classify.constantize.where(updated_at: (last_time..Time.current ) )
    table_names.each do |tab|
      next if tab.eql?table_names[0]
      my_attribs = get_attributes(tab).rows.flatten

      applicable_data = query_data.select(my_attribs.join(','))
      # my_model = model_name.classify.constantize
      # all_attribs =  my_model.columns.map{|x| x.name.to_sym }
      # data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))

      query_coll = applicable_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}

      query_coll.each do |qc|
        @db[tab.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
      end

    end

  end


  desc "update_dependents", "updates dependent tables with data from master table"
  def update_composed(table_names,last_time)
    table_name = composed_table[0]
    model_name = table_name.split('-')
    my_attribs = get_attributes(table_name).rows.flatten

    query_data = model_name[0].singularize.classify.constantize.where(updated_at: (last_time..Time.current ) )

    # query_data = table_names[0].classify.constantize.where(updated_at: (last_time..Time.current ) )
    table_names.each do |tab|
      next if tab.eql?table_names[0]
      my_attribs = get_attributes(tab).rows.flatten

      applicable_data = query_data.select(my_attribs.join(','))
      # my_model = model_name.classify.constantize
      # all_attribs =  my_model.columns.map{|x| x.name.to_sym }
      # data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))

      query_coll = applicable_data.each {|qr| qr.attributes.keys.zip(qr.attributes.values).to_h}

      query_coll.each do |qc|
        @db[table_name.to_sym].insert_conflict(:target=>:id, :update=>qc.attributes).insert(qc.attributes)
      end

    end

  end


  desc "create fact old", "create Fact Table. Accepts string table_name"
  def create_fact_old(model_name)
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
    @db[model_name].all
  end

  desc "disconnect", "Disconnect backend connection"
  def db_disconnect
    @db.close
  end

  desc "extract_and_load", "copy bulk data from one data table to another. Accepts string"
  def extract_load(model_name,last_scan)

    my_model = model_name.classify.constantize
    all_attribs =  my_model.columns.map{|x| x.name.to_sym }
    data =  convert(my_model.where(updated_at: (1.day.ago..Time.current ) ))

    @db[model_name.pluralize.downcase.to_sym].import(all_attribs, data )

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