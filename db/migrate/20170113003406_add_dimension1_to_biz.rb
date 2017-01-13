class AddDimension1ToBiz < ActiveRecord::Migration
  def change
    (1..5).each do |e|
      add_column :bizs, "dimension_#{e}", :string
      add_column :bizs, "measures_#{e}", :string
    end

  end
end
