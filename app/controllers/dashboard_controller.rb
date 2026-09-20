class DashboardController < ApplicationController
  before_action :require_login

  def show
    @show_caches = ShowCache.find_all(current_user.bands, current_user.zips)
  end
end
