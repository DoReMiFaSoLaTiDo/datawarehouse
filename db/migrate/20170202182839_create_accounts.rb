class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :account_name
      t.decimal :account_balance, precision: 8, scale: 2
      t.references :customer, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
