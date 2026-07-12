# Wraps the Firestore users/{e164_phone} document shared with the Python
# webhook/poller (see shared/db.py in the show-list repo). Field names must
# stay identical across both systems since they read/write the same doc.
# Not ActiveRecord — there is no SQL database in this app.
class User
  include ActiveModel::SecurePassword

  attr_reader :phone

  has_secure_password validations: false

  def self.collection
    FIRESTORE.col("users")
  end

  def self.find(phone)
    snapshot = collection.doc(phone).get
    return nil unless snapshot.exists?

    new(phone, (snapshot.data || {}).dup)
  end

  # Mirrors shared/db.py's upsert_user: creates the doc with created_at if it
  # doesn't exist yet, otherwise leaves existing fields (zips, bands, channel,
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

  def zips = @data[:zips] || []
  def channel = @data[:channel] || "sms"
  def bands = @data[:bands] || []

  def password_digest = @data[:password_digest]

  def password_digest=(digest)
    @data[:password_digest] = digest
  end

  def has_password? = password_digest.present?

  def set_password(new_password)
    self.password = new_password
    doc_ref.set({ password_digest: password_digest }, merge: true)
  end

  def add_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_union(name) }, merge: true)
    @data[:bands] = (bands + [name]).uniq
  end

  def remove_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_delete(name) }, merge: true)
    @data[:bands] = bands - [name]
  end

  def add_zip(zip_code)
    doc_ref.set({ zips: FIRESTORE.field_array_union(zip_code) }, merge: true)
    @data[:zips] = (zips + [zip_code]).uniq
  end

  def remove_zip(zip_code)
    doc_ref.set({ zips: FIRESTORE.field_array_delete(zip_code) }, merge: true)
    @data[:zips] = zips - [zip_code]
  end

  # Persists a drag-and-drop reorder. Ignores anything in new_order that
  # isn't currently tracked, and appends anything missing from new_order, so
  # a stale or tampered client payload can't drop or duplicate entries.
  def reorder_bands(new_order)
    ordered = (new_order & bands) | bands
    doc_ref.set({ bands: ordered }, merge: true)
    @data[:bands] = ordered
  end

  def reorder_zips(new_order)
    ordered = (new_order & zips) | zips
    doc_ref.set({ zips: ordered }, merge: true)
    @data[:zips] = ordered
  end

  private

  def doc_ref
    self.class.collection.doc(phone)
  end
end
