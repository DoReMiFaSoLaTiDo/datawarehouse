class AddMeasuresToBiz < ActiveRecord::Migration
  def change
    add_column :bizs, :measures, :string, array:true, default: []
  end
end
