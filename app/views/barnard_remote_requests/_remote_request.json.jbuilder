json.extract! remote_request, :id, :created_at, :updated_at
json.url remote_request_url(remote_request, format: :json)
