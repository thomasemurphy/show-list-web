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

  # A user already known to exist — the phone in the session, which only gets
  # there after a successful login. The document isn't fetched until a field
  # is actually read, so actions that only write (removing a band, toggling
  # SMS alerts) cost no read at all.
  def self.from_session(phone)
    new(phone)
  end

  def self.exists?(phone)
    collection.doc(phone).get.exists?
  end

  # Mirrors shared/db.py's upsert_user: merge: true, so if the doc turns up
  # in the meantime (the SMS bot creating it) its fields are left untouched.
  def self.create(phone)
    collection.doc(phone).set({ created_at: FIRESTORE.field_server_time }, merge: true)
  end

  # data of nil means "not fetched yet" (see .from_session), as distinct from
  # a document that exists but has no fields.
  def initialize(phone, data = nil)
    @phone = phone
    @data = data
  end

  def guest? = false
  def band_limit_reached? = false
  def zip_limit_reached? = false

  def zips = data[:zips] || []
  def channel = data[:channel] || "sms"
  def bands = data[:bands] || []

  # Absent means the account predates this setting or has never toggled it —
  # default to enabled so existing users keep getting alerts they already had.
  def sms_alerts_enabled? = data.fetch(:sms_alerts_enabled, true)

  def sms_alerts_enabled=(enabled)
    doc_ref.set({ sms_alerts_enabled: enabled }, merge: true)
    @data[:sms_alerts_enabled] = enabled if @data
  end

  def password_digest = data[:password_digest]

  def password_digest=(digest)
    data[:password_digest] = digest
  end

  def has_password? = password_digest.present?

  def set_password(new_password)
    self.password = new_password
    doc_ref.set({ password_digest: password_digest }, merge: true)
  end

  def add_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_union(name) }, merge: true)
    @data[:bands] = (bands + [name]).uniq if @data
  end

  def remove_band(name)
    doc_ref.set({ bands: FIRESTORE.field_array_delete(name) }, merge: true)
    @data[:bands] = bands - [name] if @data
  end

  def add_zip(zip_code)
    doc_ref.set({ zips: FIRESTORE.field_array_union(zip_code) }, merge: true)
    @data[:zips] = (zips + [zip_code]).uniq if @data
  end

  def remove_zip(zip_code)
    doc_ref.set({ zips: FIRESTORE.field_array_delete(zip_code) }, merge: true)
    @data[:zips] = zips - [zip_code] if @data
  end

  # Persists a drag-and-drop reorder. Ignores anything in new_order that
  # isn't currently tracked, and appends anything missing from new_order, so
  # a stale or tampered client payload can't drop or duplicate entries.
  def reorder_bands(new_order)
    ordered = (new_order & bands) | bands
    doc_ref.set({ bands: ordered }, merge: true)
    @data[:bands] = ordered if @data
  end

  def reorder_zips(new_order)
    ordered = (new_order & zips) | zips
    doc_ref.set({ zips: ordered }, merge: true)
    @data[:zips] = ordered if @data
  end

  private

  # Writes go straight to doc_ref, so a User built by .from_session only pays
  # for the document once something reads a field. A write on an unfetched
  # user skips the local bookkeeping above (`if @data`) — there's no copy to
  # keep in step, and a later read picks the write up from Firestore.
  def data
    @data ||= (self.class.collection.doc(phone).get.data || {}).dup
  end

  def doc_ref
    self.class.collection.doc(phone)
  end
end
