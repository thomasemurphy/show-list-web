require "net/http"
require "json"
require "erb"

# Thin client for the two internal endpoints added to the Python webhook
# (webhook/main.py in the show-list repo), which keeps the precision-tuned
# SeatGeek matching logic in one place rather than porting it to Ruby.
class SeatgeekClient
  class Error < StandardError; end

  BASE_URL = ENV.fetch("SHOWLIST_API_BASE_URL")
  SHARED_SECRET = ENV.fetch("SHOWLIST_API_SHARED_SECRET")

  # Returns the SeatGeek performer slug for band_name, or nil if not found.
  def self.resolve(band_name)
    body = get("/api/bands/resolve", name: band_name)
    body["ok"] ? body["slug"] : nil
  end

  # Returns an array of event hashes for an already-resolved slug near zip_code.
  def self.shows(slug, band_name, zip_code)
    body = get("/api/bands/#{ERB::Util.url_encode(slug)}/shows", name: band_name, zip: zip_code)
    body["ok"] ? body["events"] : []
  end

  def self.get(path, params)
    uri = URI.join(BASE_URL, path)
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req["X-Internal-Secret"] = SHARED_SECRET

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(req) }
    raise Error, "#{uri} → #{res.code}" unless res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPBadRequest)

    JSON.parse(res.body)
  rescue => e
    Rails.logger.warn("SeatgeekClient request failed: #{e.message}")
    { "ok" => false, "reason" => "request_failed" }
  end
  private_class_method :get
end
