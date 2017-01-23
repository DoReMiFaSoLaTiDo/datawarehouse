require 'sequel_connector'

SequelConnector.new(Rails.env).connect_database

class DwhTable < Sequel::Model()
  plugin :foo
  self.abstract_class = true
  establish_connection "dwh_#{Rails.env}"
end