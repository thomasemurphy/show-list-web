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

  # Every band x zip pair the dashboard needs, in a single Firestore round
  # trip (BatchGetDocuments) rather than one per cell. Returns a hash keyed
  # by [band_name, zip_code], with nil for pairs that have never been checked
  # — same shape per entry as .find, so callers read it the same way.
  #
  # get_all makes no ordering guarantee and may interleave missing documents,
  # so results are matched back up by document id rather than by position.
  def self.find_all(band_names, zip_codes)
    pairs = band_names.to_a.product(zip_codes.to_a)
    return {} if pairs.empty?

    docs = pairs.map { |band_name, zip_code| collection.doc(key(band_name, zip_code)) }
    by_id = FIRESTORE.get_all(docs).each_with_object({}) do |snapshot, found|
      next unless snapshot.exists?

      events = (snapshot.data || {})[:events] || []
      found[snapshot.document_id] = { events: events.map { |event| event.transform_keys(&:to_s) } }
    end

    pairs.to_h { |band_name, zip_code| [ [ band_name, zip_code ], by_id[key(band_name, zip_code)] ] }
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
