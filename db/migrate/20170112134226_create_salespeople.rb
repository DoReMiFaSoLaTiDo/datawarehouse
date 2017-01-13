class CreateSalespeople < ActiveRecord::Migration
  def change
    create_table :salespeople do |t|
      t.string :name
      t.string :gender
      t.string :age
      t.string :height
      t.string :weight

      t.timestamps null: false
    end
  end
end
