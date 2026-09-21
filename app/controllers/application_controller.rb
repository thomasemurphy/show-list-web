class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  before_action :extend_session_expiry

  private

  # request.session_options[:expire_after] only affects the Set-Cookie header
  # on the response it's set for — the cookie store rewrites the header
  # (without it) on the very next request that touches the session (e.g. flash
  # being read), silently dropping back to a browser-session-only cookie. Keep
  # re-applying it every request for anyone who checked "stay logged in".
  def extend_session_expiry
    request.session_options[:expire_after] = 1.year if session[:persistent]
  end

  def current_user
    @current_user ||= session[:phone] && User.from_session(session[:phone])
  end

  def logged_in?
    session[:phone].present?
  end

  def require_login
    redirect_to login_path unless logged_in?
  end

  # For the pages a visitor can try before logging in (the dashboard and what
  # it posts to): current_user becomes a GuestUser backed by the session.
  def allow_guest
    @current_user = GuestUser.new(session) unless logged_in?
  end
end
