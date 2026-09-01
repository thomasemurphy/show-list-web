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

  # Returns { slug:, name: } for band_name (name is SeatGeek's canonical
  # spelling/casing for the act), or nil if not confidently matched (includes
  # the ambiguous case — callers that don't need to disambiguate treat "not
  # sure yet" the same as "not found"). For the interactive add-band flow,
  # which needs to tell an ambiguous match apart from a flat miss, use
  # resolve_interactive instead.
  def self.resolve(band_name)
    result = resolve_interactive(band_name)
    result[:status] == :confident ? { slug: result[:slug], name: result[:name] } : nil
  end

  # Returns one of:
  #   { status: :confident, slug:, name: }
  #   { status: :ambiguous, candidates: [{ slug:, name:, score: }, ...] }
  #   { status: :not_found }
  def self.resolve_interactive(band_name)
    body = get("/api/bands/resolve", name: band_name)
    case body["status"]
    when "confident"
      { status: :confident, slug: body["slug"], name: body["name"] }
    when "ambiguous"
      candidates = (body["candidates"] || []).map { |c| { slug: c["slug"], name: c["name"], score: c["score"] } }
      { status: :ambiguous, candidates: candidates }
    else
      { status: :not_found }
    end
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
