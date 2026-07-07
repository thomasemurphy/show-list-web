class ShowsController < ApplicationController
  before_action :require_login

  # ?band=<name>&zip=<code> — works for any band, not just ones the user
  # tracks, so this doubles as the "is X coming to my town" lookup.
  def index
    @band = params[:band].to_s.strip
    @zip = params[:zip].to_s.strip

    if @zip.blank?
      redirect_to dashboard_path, alert: "Choose a zip code first." and return
    end
    if @band.blank?
      redirect_to dashboard_path, alert: "Enter a band name to check." and return
    end

    slug = SeatgeekClient.resolve(@band)
    @events = slug ? SeatgeekClient.shows(slug, @band, @zip) : []
    @not_found = slug.nil?
    ShowCache.store(@band, @zip, @events)

    if turbo_frame_request?
      render partial: "shows/cell",
             locals: { band: @band, zip: @zip, events: @events, checked: true, not_found: @not_found }
    end
  end
end
