Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy

# Read-only access for files stored on prod bucket
S3_READONLY_KEY = ENV.fetch("S3_READONLY_KEY", "")
S3_READONLY_SECRET = ENV.fetch("S3_READONLY_SECRET", "")
