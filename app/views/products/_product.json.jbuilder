json.extract! product, :id, :name, :sku, :type, :price, :created_at, :updated_at
json.url product_url(product, format: :json)