class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.decimal :total_amt, precision: 8, scale: 2
      t.references :salesperson, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true
      t.references :customer, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
