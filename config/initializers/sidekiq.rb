if Rails.env.production?

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 2 }
  end

  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 20 }

    Rails.application.config.after_initialize do
      Rails.logger.info("DB Connection Pool size for Sidekiq Server before disconnect is: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
      ActiveRecord::Base.connection_pool.disconnect!

      ActiveSupport.on_load(:active_record) do
        config = Rails.application.config.database_configuration[Rails.env]
        config['reaping_frequency'] = ENV['DATABASE_REAP_FREQ'] || 10 # seconds
        # config['pool'] = ENV['WORKER_DB_POOL_SIZE'] || Sidekiq.options[:concurrency]
        config['pool'] = 16
        ActiveRecord::Base.establish_connection(config)

        Rails.logger.info("DB Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
      end
    end
  end

else
  Sidekiq.configure_client do |config|
    config.redis = { db: 1 }
    Rails.application.config.after_initialize do
      subject = {}
      subject["job"] = 'start'
      DwhWorker.perform_async(subject)
    end
  end

  Sidekiq.configure_server do |config|
    config.redis = { db: 1 }
  end

  # class OurWorker
  #   include Sidekiq::Worker
  #
  #   def perform(complexity)
  #     case complexity
  #       when "super_hard"
  #         puts "Charging a credit card..."
  #         raise "Woops! stuff got bad"
  #         puts "Grrr, Really took quite a bit of effort"
  #       when "hard"
  #         sleep 10
  #         puts "Whew! That took some time"
  #       else
  #         sleep 1
  #         puts "That was easy-peazy lemon-squezzy"
  #     end
  #   end
  # end

end