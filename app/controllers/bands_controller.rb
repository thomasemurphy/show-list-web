class BandsController < ApplicationController
  before_action :require_login

  # Mirrors webhook/tools.py's add_band: validate against SeatGeek before
  # tracking, so we never silently track a band with no real SeatGeek match.
  # Also regularizes the name to SeatGeek's canonical spelling/casing (e.g.
  # "wednesday" -> "Wednesday") rather than storing whatever the user typed.
  #
  # A query that doesn't clearly point to one act (e.g. "chase" scoring Chase
  # B, Chase Matthew, and Chase Atlantic within a few hundredths of each
  # other) re-renders the dashboard with a callout next to the Add band
  # control instead of adding anything, so the user can pick the act they
  # mean without leaving the page — mirroring the SMS bot's clarifying
  # question in webhook/tools.py's add_band. Rendering "dashboard/show" here
  # (rather than a separate view) is what keeps the rest of the page — the
  # table, nav, everything — exactly as the user left it.
  def create
    name = params[:name].to_s.strip
    if name.blank?
      redirect_to dashboard_path, alert: "Enter a band name" and return
    end

    result = SeatgeekClient.resolve_interactive(name)
    case result[:status]
    when :confident
      current_user.add_band(result[:name])
      current_user.zips.each { |zip| ShowChecker.check_resolved(result, result[:name], zip) }
      redirect_to dashboard_path, notice: "Now tracking #{result[:name]}"
    when :ambiguous
      @band_query = name
      @band_candidates = result[:candidates]
      # Turbo requires a POST response to either redirect or carry a 4xx/5xx
      # status — a plain 200 render is treated as a bug ("Form responses must
      # redirect to another location") and silently dropped. This isn't a
      # validation error, but 422 is the conventional "didn't complete, need
      # more from you" status and is what makes Turbo display the page.
      render "dashboard/show", status: :unprocessable_content
    else
      redirect_to dashboard_path, alert: "Couldn't find #{name} on SeatGeek — check the spelling?"
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
