json.extract! account, :id, :account_name, :account_balance, :customer_id, :created_at, :updated_at
json.url account_url(account, format: :json)