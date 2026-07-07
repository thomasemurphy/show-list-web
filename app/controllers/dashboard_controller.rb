class DashboardController < ApplicationController
  before_action :require_login

  def show
  end

  # Mirrors webhook/tools.py's set_zip validation: exactly 5 digits.
  def update_zip
    zip_code = params[:zip].to_s
    if zip_code.match?(/\A\d{5}\z/)
      current_user.update_zip(zip_code)
      redirect_to dashboard_path, notice: "Zip code updated."
    else
      redirect_to dashboard_path, alert: "Enter a valid 5-digit zip code."
    end
  end
end
