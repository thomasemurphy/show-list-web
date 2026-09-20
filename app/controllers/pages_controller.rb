# The public marketing and compliance pages, previously a GitHub Pages site
# served at the showlist.live apex (show-list/docs in the bot's repo). They
# moved here when the apex started pointing at this app.
#
# Each view is a complete, self-contained HTML document with its own styling —
# deliberately not the application layout, so the pages look exactly as they
# did on the old site.
#
# No require_login: these are the pages strangers and Twilio's A2P reviewers
# see.
class PagesController < ApplicationController
  layout false

  def about; end

  # Linked from the A2P 10DLC registration. Rails routes /privacy.html here
  # too (the (.:format) suffix), so the old flat-file URLs keep working.
  def privacy; end

  def terms; end
end
