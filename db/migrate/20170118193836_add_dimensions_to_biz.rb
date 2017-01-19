class AddDimensionsToBiz < ActiveRecord::Migration
  def change
    add_column :bizs, :dimensions, :string, array:true, default: []
  end
end
