require 'pg'

def datawarehouse_database
  @client ||= PG.connect( dbname: "dwh_#{Rails.env}")
end

namespace(:db) do
  namespace(:import_data) do

  end

  namespace(:create_tables) do
    desc "create fact table"
    task :facts, [:model_name] => :environment do

    end

    desc "create dimension tables"
    task :dimensions => :environment do
      ARGV.each { |dim| task dim.constantize}
    end
  end
end