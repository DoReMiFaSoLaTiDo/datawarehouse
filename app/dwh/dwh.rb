class DwhTable
  self.abstract_class = true
  establish_connection "dwhouse_#{Rails.env}"
end