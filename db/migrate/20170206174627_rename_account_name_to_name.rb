class RenameAccountNameToName < ActiveRecord::Migration
  def change
    rename_column :accounts, :account_name, :name
  end
end
