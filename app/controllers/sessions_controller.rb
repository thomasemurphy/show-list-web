class SessionsController < ApplicationController
  def new
  end

  # Step 1: user submits a phone number, we text them a code.
  def create
    phone = PhoneNumber.normalize(params[:phone])
    if phone.nil?
      flash.now[:alert] = "Enter a valid 10-digit US phone number"
      return render :new, status: :unprocessable_entity
    end

    if TwilioVerifyClient.send_code(phone)
      session[:pending_phone] = phone
      redirect_to login_verify_path
    else
      flash.now[:alert] = "Couldn't send a code to that number. Try again"
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
      # current_user assumes the document exists. This is the only entry point
      # that can see a number for the first time — the password login requires
      # an existing user, and the SMS bot creates its own.
      new_user = !User.exists?(phone)
      User.create(phone) if new_user
      adopt_guest_list(phone, include_zips: new_user)
      remember_me if params[:stay_logged_in] == "1"
      redirect_to dashboard_path, notice: "Logged in"
    else
      flash.now[:alert] = "Incorrect or expired code"
      render :new_code, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out"
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
      adopt_guest_list(phone, include_zips: false)
      remember_me if params[:stay_logged_in] == "1"
      redirect_to dashboard_path, notice: "Logged in"
    else
      flash.now[:alert] = "Incorrect phone number or password"
      render :new_password, status: :unprocessable_entity
    end
  end

  private

  # Bands a visitor added to the dashboard before logging in carry over to
  # their account, on top of anything already there. Zips only carry over for
  # a brand-new account: a returning user's zips are where they actually want
  # alerts, and the ones they typed while trying the page out may not be.
  #
  # A returning user's zips were never paired with the adopted bands while
  # they were a guest, so any pair nobody has checked yet gets checked now,
  # as BandsController#create would have — otherwise those cells read "Not
  # checked yet". A new account's pairs were all checked as the guest added
  # them.
  def adopt_guest_list(phone, include_zips:)
    guest = GuestUser.new(session)
    bands, zips = guest.bands, guest.zips
    guest.clear

    user = User.from_session(phone)
    bands.each { |band| user.add_band(band) }
    zips.each { |zip| user.add_zip(zip) } if include_zips
    return if include_zips || bands.empty?

    ShowCache.find_all(bands, user.zips).each do |(band, zip), cached|
      ShowChecker.check(band, zip) unless cached
    end
  end

  def remember_me
    session[:persistent] = true
    request.session_options[:expire_after] = 1.year
  end
end
