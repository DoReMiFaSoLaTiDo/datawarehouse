class Biz < ActiveRecord::Base
  # scope :with_scope, -> { where(id: ARRAY_COLLECTION.map(&:id)) }
  validates :fact, :dimensions, :measures, presence: true
end
