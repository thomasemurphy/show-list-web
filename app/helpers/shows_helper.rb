# Formats a show's local date/time for display, tagging it with the venue's
# rough time zone abbreviation. There's no venue timezone in the SeatGeek data
# we store (see ShowCache), so the zone is inferred from the zip code the show
# was searched near — shows are found within 50mi of that zip, so it's the
# same zone as the venue in all but a handful of border cases.
module ShowsHelper
  ZIP_PREFIX_ZONES = {
    "0" => "ET", "1" => "ET", "2" => "ET", "3" => "ET", "4" => "ET",
    "5" => "CT", "6" => "CT", "7" => "CT",
    "8" => "MT",
    "9" => "PT",
  }.freeze

  # 3-digit zip prefix ranges that don't follow the first-digit rule above.
  ZIP_PREFIX_EXCEPTIONS = {
    ("967".."968") => "HT",  # Hawaii
    ("995".."999") => "AKT", # Alaska
    ("850".."865") => "MT",  # Arizona
    ("590".."599") => "MT",  # Montana (digit 5 is otherwise Central)
    ("798".."799") => "MT",  # El Paso, TX (digit 7 is otherwise Central)
  }.freeze

  def event_datetime(datetime_local, zip)
    time = Time.parse(datetime_local)
    zone = zip_timezone_abbr(zip)
    formatted = time.strftime("%-l:%M %P")
    zone ? "#{formatted} #{zone}" : formatted
  rescue ArgumentError, TypeError
    datetime_local
  end

  private

  def zip_timezone_abbr(zip)
    prefix = zip.to_s[0, 3]
    _, zone = ZIP_PREFIX_EXCEPTIONS.find { |range, _| range.include?(prefix) }
    zone || ZIP_PREFIX_ZONES[zip.to_s[0]]
  end
end
