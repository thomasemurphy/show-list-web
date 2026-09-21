# A visitor who hasn't logged in yet, trying the dashboard out. Quacks like
# User for everything the dashboard, bands and zips controllers touch, but
# keeps its bands and zips in the session cookie instead of Firestore — there
# is no phone number to key a document by. Capped at BAND_LIMIT/ZIP_LIMIT,
# past which the dashboard asks them to log in; on login the list is copied
# onto their real account (see SessionsController#adopt_guest_list).
class GuestUser
  BAND_LIMIT = 2
  ZIP_LIMIT = 2

  def initialize(session)
    @session = session
  end

  def guest? = true

  def bands = list("bands")
  def zips = list("zips")

  def band_limit_reached? = bands.size >= BAND_LIMIT
  def zip_limit_reached? = zips.size >= ZIP_LIMIT

  def add_band(name) = write("bands", (bands + [name]).uniq)
  def remove_band(name) = write("bands", bands - [name])
  def add_zip(zip_code) = write("zips", (zips + [zip_code]).uniq)
  def remove_zip(zip_code) = write("zips", zips - [zip_code])

  # Same tamper-proofing as User#reorder_bands.
  def reorder_bands(new_order) = write("bands", (new_order & bands) | bands)
  def reorder_zips(new_order) = write("zips", (new_order & zips) | zips)

  def clear
    @session.delete(:guest)
  end

  private

  def list(key)
    Array((@session[:guest] || {})[key])
  end

  def write(key, values)
    @session[:guest] = (@session[:guest] || {}).merge(key => values)
  end
end
