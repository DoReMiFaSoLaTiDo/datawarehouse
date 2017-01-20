class DwhTable
  self.abstract_class = true
  establish_connection "dwh_#{Rails.env}"
end