class DashboardController < ApplicationController
  before_action :allow_guest

  def show
    @show_caches = ShowCache.find_all(current_user.bands, current_user.zips)
  end
end
