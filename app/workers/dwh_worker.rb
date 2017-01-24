class DwhWorker
  include Sidekiq::Worker



  def perform(options={})
    # Do something

    requested_action = options["job"]
    # raise requested_action.inspect
    case requested_action
      when "super-hard"
        puts "Charging a credit card..."
        raise "Woops! stuff got bad"
        puts "Grrr, Really took quite a bit of effort"
      when "create"
        dw ||= DwhSetup.new
        dw.create_dimensions(options["dimensions"])
        dw.create_fact(options["fact"])
        puts "New Schema created for #{options['fact']}"
      when "mail"
        OrderMailer.received(args[0..-2])
        puts "Mail has been sent"
      else
        # raise options.inspect
        sleep 1
        puts "This is DwhWorker"
    end
  end
end
