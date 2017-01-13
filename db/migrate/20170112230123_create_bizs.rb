class CreateBizs < ActiveRecord::Migration
  def change
    create_table :bizs do |t|
      t.string :fact
      t.string :dimension, array: true

      t.timestamps null: false
    end
  end
end
