json.extract! sale, :id, :total_amt, :salesperson_id, :product_id, :customer_id, :created_at, :updated_at
json.url sale_url(sale, format: :json)