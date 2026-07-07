# Wraps the Firestore shows_cache/{normalized_band}_{zip} doc shared with the
# Python poller (see shared/db.py's set_show_cache in the show-list repo),
# which refreshes every active pair daily. Not ActiveRecord.
class ShowCache
  def self.collection
    FIRESTORE.col("shows_cache")
  end

  def self.key(band_name, zip_code)
    "#{band_name.to_s.downcase.gsub(/[^a-z0-9]/, "")}_#{zip_code}"
  end

  # Returns { events: [...] } (string-keyed event hashes) or nil if this pair
  # has never been checked.
  def self.find(band_name, zip_code)
    snapshot = collection.doc(key(band_name, zip_code)).get
    return nil unless snapshot.exists?

    events = (snapshot.data || {})[:events] || []
    { events: events.map { |event| event.transform_keys(&:to_s) } }
  end

  def self.store(band_name, zip_code, events)
    collection.doc(key(band_name, zip_code)).set({
      band_name: band_name,
      zip: zip_code,
      events: events,
      updated_at: FIRESTORE.field_server_time,
    })
  end
end
