class CreateTransactionLogs < ActiveRecord::Migration
  def change
    create_table :transaction_logs do |t|
      t.integer :tran_type
      t.decimal :amount, precision: 8, scale: 2
      t.references :account, index: true, foreign_key: true
      t.references :salesperson, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
