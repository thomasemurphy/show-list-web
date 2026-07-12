module ShowsHelper
  def event_date(datetime_local)
    Time.parse(datetime_local).strftime("%A %B %-d, %Y")
  rescue ArgumentError, TypeError
    datetime_local
  end

  def event_time(datetime_local)
    Time.parse(datetime_local).strftime("%-l:%M %P")
  rescue ArgumentError, TypeError
    datetime_local
  end
end
