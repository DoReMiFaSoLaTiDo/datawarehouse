json.extract! transaction_log, :id, :tran_type, :amount, :account_id, :salesperson_id, :created_at, :updated_at
json.url transaction_url(transaction_log, format: :json)