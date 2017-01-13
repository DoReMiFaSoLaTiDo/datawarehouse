class Sale < ActiveRecord::Base
  belongs_to :salesperson
  belongs_to :product
  belongs_to :customer
end
