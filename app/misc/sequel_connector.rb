class SequelConnector
  def initialize(env)
    @env = env
    load_database_config
    # @params = @database_config["dwhouse_#{@env}"]
    @params = @database_config[@env]
  end
  def connect_database
    Sequel.connect(
        :adapter => adapter,
        :host => @params['host'],
        :database => @params['database'],
        :user => @params['user'],
        :password => @params['password'],
        :loggers => loggers
    )
  end
  private
  # Sequel adapter name for PostgreSQL is postgres and for ActiveRecord is postgresql
  def adapter
    @params['adapter'].sub('postgresql', 'postgres')
  end
  def loggers
    @env == 'development' ? [Logger.new($stdout)] : nil
  end
  def load_database_config
    @config_file ||= File.expand_path('./config/database.yml')
    @database_config ||= File.open(@config_file) {|file| YAML.load(file) }
  end
end