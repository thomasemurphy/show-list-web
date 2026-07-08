class BandsController < ApplicationController
  before_action :require_login

  # Mirrors webhook/tools.py's add_band: validate against SeatGeek before
  # tracking, so we never silently track a band with no real SeatGeek match.
  # Also regularizes the name to SeatGeek's canonical spelling/casing (e.g.
  # "wednesday" -> "Wednesday") rather than storing whatever the user typed.
  def create
    name = params[:name].to_s.strip
    if name.blank?
      redirect_to dashboard_path, alert: "Enter a band name." and return
    end

    resolved = SeatgeekClient.resolve(name)
    if resolved.nil?
      redirect_to dashboard_path, alert: "Couldn't find #{name} on SeatGeek — check the spelling?"
    else
      current_user.add_band(resolved[:name])
      redirect_to dashboard_path, notice: "Now tracking #{resolved[:name]}."
    end
  end

  def destroy
    current_user.remove_band(params[:name])
    redirect_to dashboard_path, notice: "Stopped tracking #{params[:name]}."
  end
end
