# Resolves a band on SeatGeek, fetches its shows near zip_code, and caches
# the result. The single "check" operation behind adding a band, adding a
# zip, and manually refreshing a dashboard cell.
class ShowChecker
  def self.check(band_name, zip_code)
    check_resolved(SeatgeekClient.resolve(band_name), band_name, zip_code)
  end

  # For callers that already resolved the band (e.g. band-add, which
  # resolves once to canonicalize the name) and don't want to resolve again
  # per zip code.
  def self.check_resolved(resolved, band_name, zip_code)
    events = resolved ? SeatgeekClient.shows(resolved[:slug], band_name, zip_code) : []
    ShowCache.store(band_name, zip_code, events)
    { events: events, not_found: resolved.nil? }
  end
end
