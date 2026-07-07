# Wraps the Firestore users/{e164_phone} document shared with the Python
# webhook/poller (see shared/db.py in the show-list repo). Field names must
# stay identical across both systems since they read/write the same doc.
# Not ActiveRecord — there is no SQL database in this app.
class User
  attr_reader :phone

  def self.collection
    FIRESTORE.col("users")
  end

  def self.find(phone)
    snapshot = collection.doc(phone).get
    return nil unless snapshot.exists?

    new(phone, (snapshot.data || {}).dup)
  end

  # Mirrors shared/db.py's upsert_user: creates the doc with created_at if it
  # doesn't exist yet, otherwise leaves existing fields (zip, bands, channel,
  # messages) untouched.
  def self.find_or_create(phone)
    find(phone) || begin
      collection.doc(phone).set({ created_at: FIRESTORE.field_server_time }, merge: true)
      find(phone)
    end
  end

  def initialize(phone, data = {})
    @phone = phone
    @data = data
  end

  def zip = @data[:zip]
  def channel = @data[:channel] || "sms"
  def bands = @data[:bands] || []

  def add_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_union(name) }, merge: true)
    @data[:bands] = (bands + [name]).uniq
  end

  def remove_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_delete(name) }, merge: true)
    @data[:bands] = bands - [name]
  end

  def update_zip(zip_code)
    doc_ref.set({ zip: zip_code }, merge: true)
    @data[:zip] = zip_code
  end

  private

  def doc_ref
    self.class.collection.doc(phone)
  end
end
