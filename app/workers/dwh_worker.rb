class DwhWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'dwh'

  cattr_accessor :last_check_time, :task_completed, :tasks_todo
  @@last_check_time ||= 1.day.ago
  @@task_completed = true
  @@tasks_todo = 0

  def self.decrement
    @@tasks_todo -= 1
  end

  def self.complete
    @@task_completed = true
  end

  def self.complete?
    @@task_completed
  end

  def self.set_busy
    @@task_completed = false
  end

  def self.set_tasks_todo(num)
    @@tasks_todo = num
  end

  def self.get_tasks_todo
    @@tasks_todo
  end

  def self.get_last_scan
    @@last_check_time
  end

  # scans models to identify those that have changed since last scan
  def self.read_tables
    last_scan, @@last_check_time = @@last_check_time, Time.current

    # only created tables need to be updated
    etl_tables = []
    @ar_conn ||= ActiveRecord::Base.connection
    the_tables = @ar_conn.tables.select{ |tt| tt if tt[/\d/]}
    the_models = the_tables.map{|tab| tab.split('-')[0].singularize}.uniq

    the_models.each do |model_klass|

      record = model_klass.classify.constantize.where(updated_at: (last_scan..Time.current ) )
      if record.any?
        puts "record found for #{model_klass}"
        etl_tables.push(model_klass)
      end
    end

    if etl_tables.any?
      @ar_conn ||= ActiveRecord::Base.connection
      the_tables = @ar_conn.tables
      self.set_busy
      self.set_tasks_todo(etl_tables.size)
      etl_tables.each do |tab|
        my_tables = the_tables.select{ |tt| tt if tt[/\d/] && tt.start_with?(tab)}
        my_tables.unshift(tab)
        subject = {}
        subject["job"] = "bulk_update"
        subject["table"] = my_tables
        perform_async(subject)
      end
    end

    Rails.logger.info("Fact and Dimension tables updated at #{Time.current}")

  end


  def table_set

    masters = the_tables.reject{|tt| tt if tt[/\d/]}
    dependents = the_tables.select{|tt| tt if tt[/\d/]}
    master_dependents = {}
    masters.each do |master|
      master_dependents[master] = [master]
      master_dependents[master].push()
    end
  end

  def perform(opts={})
    # Do something

    requested_action = opts["job"]
    case requested_action

      when "bulk_update"
        @dw ||= DwhSetup.new
        @dw.updator(opts['table'], self.class.get_last_scan)
        puts "Data Table loaded for #{opts['table']}"
        self.class.decrement
        if self.class.get_tasks_todo == 0
          self.class.complete
        end

      when "bulk_update_old"
        @dw ||= DwhSetup.new
        @dw.bulk_insert_update(opts['table'], self.class.get_last_scan)
        puts "Data Table loaded for #{opts['table']}"
        self.class.decrement
        if self.class.get_tasks_todo == 0
          self.class.complete
        end

      when "create"
        # raise opts.inspect
        @dw ||= DwhSetup.new
        res = @dw.create_dimensions(opts)
        puts "New Schemas created for #{res}"

      when "create_old"
        # raise opts.inspect
        @dw ||= DwhSetup.new
        @dw.create_dimensions_old(opts["dimensions"])
        @dw.create_fact(opts["fact"])
        puts "New Schema created for #{opts['fact']}"


      when "start"
        if self.class.complete? && Time.current > self.class.get_last_scan + 2.minutes
          puts "Getting started"
          self.class.read_tables
          subject = {}
          subject['job'] = 'start'
          self.class.perform_async(subject)
        else
          puts "Seems last check was less than 2 minutes ago (#{self.class.get_last_scan}). Waiting 2 minutes"
          subject = {}
          subject['job'] = 'start'
          self.class.perform_in(2.minutes, subject)
        end

      else
        puts "This is default operation DwhWorker"

    end



    #   when "etl"
    #     dw ||= DwhSetup.new
    #     dw.extract_load(options["table"],options["id"])
    #     puts "Data Table updated for #{options['table']}"
    #     self.perform_in(15.minutes, DwhJobs.update_records())
    #   when "insert"
    #     dw ||= DwhSetup.new
    #     dw.insert_update(options["table"],options["id"])
    #     puts "New Record inserted into #{options['table']}"
    #
    #   when "delete"
    #     dw ||= DwhSetup.new
    #     dw.delete(options["table"],options["id"])
    #     puts "Record deleted from #{options['table']}"
    #   when "start"
    #     tis = 180
    #     DwhJobs.update_models
    #     DwhJobs.update_records()
    #     puts "Models and records have been updated at #{Time.current}. Scheduling next update after #{tis} seconds"
    #     sleep(tis)
    #     subject = {}
    #     subject["job"] = 'start'
    #     DwhWorker.new.perform(subject)
    #   else
    #     # raise options.inspect
    #     sleep 1
    #     puts "This is default operation DwhWorker"
    # end
  end
end
