class BandsController < ApplicationController
  before_action :allow_guest

  # Mirrors webhook/tools.py's add_band: validate against SeatGeek before
  # tracking, so we never silently track a band with no real SeatGeek match.
  # Also regularizes the name to SeatGeek's canonical spelling/casing (e.g.
  # "wednesday" -> "Wednesday") rather than storing whatever the user typed.
  #
  # A query that doesn't clearly point to one act (e.g. "chase", which could
  # be Chase Atlantic, Chase Rice or Chase & Status) re-renders the dashboard
  # with a callout next to the Add band control instead of adding anything, so
  # the user can pick the act they mean without leaving the page — mirroring
  # the SMS bot's clarifying question in webhook/tools.py's add_band. The
  # question and the one-line description of each act come from the webhook's
  # Gemini resolver, which only asks when the acts are genuinely different
  # people; a mere misspelling ("mumford and sons") it settles itself.
  # Rendering "dashboard/show" here (rather than a separate view) is what
  # keeps the rest of the page — the table, nav, everything — exactly as the
  # user left it.
  #
  # Outcomes go in flash[:band_notice]/[:band_alert] rather than the usual
  # notice/alert, which routes them to the popover next to the Add band
  # control instead of the banner at the top of the page (see
  # ApplicationHelper::ANCHORED_FLASH_KEYS). Adding a band happens at the
  # bottom of a table that's often taller than the window, and a message
  # announcing itself off-screen above isn't a message.
  #
  # For the same reason these redirect back to the URL the form was submitted
  # from rather than to dashboard_path. The dashboard answers at both "/" and
  # "/dashboard", and Turbo only preserves scroll position (turbo-refresh-scroll
  # in the layout) for a visit it considers a page refresh — which it decides
  # by comparing the redirect target against the current URL *exactly*:
  #
  #   redirected && location.href === this.location.href ? "replace" : "advance"
  #
  # So adding a band from "/" and redirecting to "/dashboard" is an "advance",
  # and Turbo scrolls to the top — dumping the user at the top of the page
  # away from both the control they were using and the message meant for them.
  def create
    if current_user.band_limit_reached?
      redirect_to login_path, notice: "Log in to track more than #{GuestUser::BAND_LIMIT} bands" and return
    end

    name = params[:name].to_s.strip
    if name.blank?
      redirect_back_or_to dashboard_path, flash: { band_alert: "Enter a band name" } and return
    end

    result = SeatgeekClient.resolve_interactive(name)
    case result[:status]
    when :confident
      current_user.add_band(result[:name])
      current_user.zips.each { |zip| ShowChecker.check_resolved(result, result[:name], zip) }
      redirect_back_or_to dashboard_path, flash: { band_notice: "Now tracking #{result[:name]}" }
    when :ambiguous
      @band_query = name
      @band_question = result[:question]
      @band_candidates = result[:candidates]
      # Rendering dashboard/show means supplying what that view loads in its
      # controller — see DashboardController#show.
      @show_caches = ShowCache.find_all(current_user.bands, current_user.zips)
      # Turbo requires a POST response to either redirect or carry a 4xx/5xx
      # status — a plain 200 render is treated as a bug ("Form responses must
      # redirect to another location") and silently dropped. This isn't a
      # validation error, but 422 is the conventional "didn't complete, need
      # more from you" status and is what makes Turbo display the page.
      render "dashboard/show", status: :unprocessable_content
    else
      # The resolver usually explains itself ("I couldn't find a listing for
      # Radiohead on SeatGeek") — better than guessing it was a typo when it
      # searched the web and concluded the act simply isn't listed.
      redirect_back_or_to dashboard_path,
                          flash: { band_alert: result[:reason] ||
                                               "Couldn't find #{name} on SeatGeek — check the spelling?" }
    end
  end

  def destroy
    current_user.remove_band(params[:name])
    redirect_to dashboard_path, notice: "Stopped tracking #{params[:name]}"
  end

  def reorder
    current_user.reorder_bands(Array(params[:order]))
    head :ok
  end
end
