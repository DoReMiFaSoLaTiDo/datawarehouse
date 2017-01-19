class RemoveDimensionFromBiz < ActiveRecord::Migration
  def change
    remove_column :bizs, :dimension, :string
  end
end
