class ZipsController < ApplicationController
  before_action :require_login

  # Mirrors webhook/tools.py's set_zip validation: exactly 5 digits.
  def create
    zip_code = params[:code].to_s
    if zip_code.match?(/\A\d{5}\z/)
      current_user.add_zip(zip_code)
      current_user.bands.each { |band| ShowChecker.check(band, zip_code) }
      redirect_to dashboard_path, notice: "Zip code added."
    else
      redirect_to dashboard_path, alert: "Enter a valid 5-digit zip code."
    end
  end

  def destroy
    current_user.remove_zip(params[:code])
    redirect_to dashboard_path, notice: "Removed zip code #{params[:code]}."
  end
end
