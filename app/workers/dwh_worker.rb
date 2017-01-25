class DwhWorker
  include Sidekiq::Worker



  def perform(options={})
    # Do something

    requested_action = options["job"]
    # raise requested_action.inspect
    case requested_action
      when "create"
        dw ||= DwhSetup.new
        dw.create_dimensions(options["dimensions"])
        dw.create_fact(options["fact"])
        puts "New Schema created for #{options['fact']}"
      when "etl"
        dw ||= DwhSetup.new
        dw.extract_load(options["table"])
        puts "Data Table loaded for #{options['table']}"
      when "update"
        dw ||= DwhSetup.new
        dw.insert_update(options["table"],options["id"])
        puts "Data Table updated for #{options['table']}"
      when "insert"
        dw ||= DwhSetup.new
        dw.insert_update(options["table"],options["id"])
        puts "New Record inserted into #{options['table']}"
      when "delete"
        dw ||= DwhSetup.new
        dw.delete(options["table"],options["id"])
        puts "Record deleted from #{options['table']}"
      else
        # raise options.inspect
        sleep 1
        puts "This is default operation DwhWorker"
    end
  end
end
