class RenameTableTransactionLog < ActiveRecord::Migration
  def change
    rename_table :transaction_logs, :transactions
  end
end
