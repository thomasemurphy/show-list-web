class ZipsController < ApplicationController
  before_action :allow_guest

  # Mirrors webhook/tools.py's set_zip validation: exactly 5 digits.
  def create
    if current_user.zip_limit_reached?
      redirect_to login_path, notice: "Log in to add more than #{GuestUser::ZIP_LIMIT} zip codes" and return
    end

    zip_code = params[:code].to_s
    if zip_code.match?(/\A\d{5}\z/)
      current_user.add_zip(zip_code)
      # Don't check bands against the new zip here — with enough tracked
      # bands that sequential SeatGeek fan-out blows past Heroku's 30s
      # router timeout (H12) even though the app keeps working in the
      # background. The new column renders "Not checked yet" for every
      # band instead, and the dashboard's checker controller walks it
      # band-by-band client-side (see shows/_cell.html.erb).
      redirect_to dashboard_path, notice: "Zip code added"
    else
      redirect_to dashboard_path, alert: "Enter a valid 5-digit zip code"
    end
  end

  def destroy
    current_user.remove_zip(params[:code])
    redirect_to dashboard_path, notice: "Removed zip code #{params[:code]}"
  end

  def reorder
    current_user.reorder_zips(Array(params[:order]))
    head :ok
  end
end
