class SessionsController < ApplicationController
  def new
  end

  # Step 1: user submits a phone number, we text them a code.
  def create
    phone = PhoneNumber.normalize(params[:phone])
    if phone.nil?
      flash.now[:alert] = "Enter a valid 10-digit US phone number."
      return render :new, status: :unprocessable_entity
    end

    if TwilioVerifyClient.send_code(phone)
      session[:pending_phone] = phone
      redirect_to login_verify_path
    else
      flash.now[:alert] = "Couldn't send a code to that number. Try again."
      render :new, status: :unprocessable_entity
    end
  end

  # Step 2: form to enter the code just texted.
  def new_code
    redirect_to login_path and return unless session[:pending_phone]
  end

  # Step 2 submit: check the code, establish the session on success.
  def verify_code
    phone = session[:pending_phone]
    if phone.nil?
      redirect_to login_path and return
    end

    if TwilioVerifyClient.check_code(phone, params[:code])
      session.delete(:pending_phone)
      session[:phone] = phone
      remember_me if params[:stay_logged_in] == "1"
      redirect_to dashboard_path, notice: "Logged in."
    else
      flash.now[:alert] = "Incorrect or expired code."
      render :new_code, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out."
  end

  # Password login form.
  def new_password
  end

  # Password login submit.
  def create_with_password
    phone = PhoneNumber.normalize(params[:phone])
    user = phone && User.find(phone)

    if user&.has_password? && user.authenticate(params[:password])
      session[:phone] = phone
      remember_me if params[:stay_logged_in] == "1"
      redirect_to dashboard_path, notice: "Logged in."
    else
      flash.now[:alert] = "Incorrect phone number or password."
      render :new_password, status: :unprocessable_entity
    end
  end

  private

  def remember_me
    session[:persistent] = true
    request.session_options[:expire_after] = 1.year
  end
end
