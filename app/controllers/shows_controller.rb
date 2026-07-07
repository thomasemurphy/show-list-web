class ShowsController < ApplicationController
  before_action :require_login

  # ?band=<name> — works for any band, not just ones the user tracks, so this
  # doubles as the "is X coming to my town" lookup.
  def index
    @band = params[:band].to_s.strip

    if current_user.zip.blank?
      redirect_to dashboard_path, alert: "Set your zip code first." and return
    end
    if @band.blank?
      redirect_to dashboard_path, alert: "Enter a band name to check." and return
    end

    slug = SeatgeekClient.resolve(@band)
    @events = slug ? SeatgeekClient.shows(slug, @band, current_user.zip) : []
    @not_found = slug.nil?
  end
end
