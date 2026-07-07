require "google/cloud/firestore"
require "base64"

firestore_options = { project_id: ENV.fetch("GCP_PROJECT_ID") }

if (encoded = ENV["GCP_CREDENTIALS_JSON_BASE64"]).present?
  firestore_options[:credentials] = JSON.parse(Base64.decode64(encoded))
end

# In development FIRESTORE_EMULATOR_HOST points this at the same emulator the
# Python webhook/poller use locally; the gem detects that env var itself and
# skips real auth, so firestore_options is unchanged either way.
FIRESTORE = Google::Cloud::Firestore.new(**firestore_options)
