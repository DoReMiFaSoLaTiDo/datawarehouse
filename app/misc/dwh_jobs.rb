module DwhJobs
  def create_table

    the_table = Biz.where(updated_at: (Time.current - 15.minutes)..Time.current )
    unique_fact = the_table.map(&:fact)
    unique_dimensions = the_table.map(&:dimensions).flatten.to_set

    if the_table
      the_table.each do |record|
        DwhEngine.new(record).create_relation
      end
    end
  end

  def update_table
    the_table = Biz.where(updated_at: (Time.current - 15.minutes)..Time.current )
    unique_fact = the_table.map(&:fact)
    unique_dimensions = the_table.map(&:dimensions).flatten.to_set

    if unique_fact || unique_dimensions
      all_tables = unique_fact || unique_dimensions
      all_tables.each {|record| DwhEngine.new(record).update_record}
    end

  end

  def self.find_and_update_records(operation = nil)
    case operation
      when 'create'
        the_table = Biz.where(updated_at: (Time.current - 15.minutes)..Time.current )
        if the_table
          the_table.each do |record|
            DwhEngine.new(record).create_relation
          end
        end
        Rails.logger.info("Fact and Dimension tables created at #{Time.current}")
      when 'update'
        the_table = Biz.pluck(:id, :fact, :dimensions)
        unique_fact = the_table.map(&:fact)
        unique_dimensions = the_table.map(&:dimensions).flatten.to_set
        all_tables = unique_fact || unique_dimensions
        all_tables.each do |model_klass|
          record = model_klass.where(updated_at: (Time.current - 15.minutes)..Time.current )
          if record
            record.each do |rec|
              DwhEngine.new(rec).update_record
            end
          end
        end
        Rails.logger.info("Fact and Dimension tables updated at #{Time.current}")
    end
  end

  def self.update_records
    the_table = Biz.pluck(:id, :fact, :dimensions)
    unique_fact = the_table.map(&:fact)
    unique_dimensions = the_table.map(&:dimensions).flatten.to_set
    all_tables = unique_fact || unique_dimensions
    all_tables.each do |model_klass|
      record = model_klass.where(updated_at: (Time.current - 15.minutes)..Time.current )
      if record
        record.each do |rec|
          DwhEngine.new(rec).update_record
        end
      end
    end
    Rails.logger.info("Fact and Dimension tables updated at #{Time.current}")
  end

  def self.update_models
    the_table = Biz.where(updated_at: (Time.current - 15.minutes)..Time.current )
    if the_table
      the_table.each do |record|
        DwhEngine.new(record).create_relation
      end
    end
    Rails.logger.info("Fact and Dimension tables created at #{Time.current}")
  end
end