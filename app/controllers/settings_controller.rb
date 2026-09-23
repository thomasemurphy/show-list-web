class SettingsController < ApplicationController
  before_action :require_login

  def show
  end

  def update_password
    if current_user.has_password? && !current_user.authenticate(params[:current_password])
      flash.now[:alert] = "Current password is incorrect"
      return render :show, status: :unprocessable_entity
    end

    if params[:new_password].blank? || params[:new_password] != params[:new_password_confirmation]
      flash.now[:alert] = "New passwords didn't match"
      return render :show, status: :unprocessable_entity
    end

    current_user.set_password(params[:new_password])
    redirect_to settings_path
  end

  def update_notifications
    current_user.sms_alerts_enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
    head :ok
  end
end
