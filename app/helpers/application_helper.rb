module ApplicationHelper
  # Flash entries that belong next to the control that produced them rather
  # than in the banner at the top of the page. Adding a band happens at the
  # bottom of the dashboard table, so its outcome is shown there — see
  # bands/_add_control — where the person who just clicked Add is looking.
  ANCHORED_FLASH_KEYS = %w[band_alert].freeze

  # The flash entries the layout's top-of-page banner should render.
  def page_flashes
    flash.to_hash.except(*ANCHORED_FLASH_KEYS)
  end

  # The add-a-band error message, or nil. Successful actions show no message
  # at all — the page itself reflects the change.
  def band_flash
    flash[:band_alert].presence
  end

  # Tailwind classes for an error message, shared by the top-of-page banner
  # and the popover anchored to the Add band control so the two read as the
  # same kind of message.
  def flash_classes
    "bg-red-50 text-red-700 border-red-100 dark:bg-red-950/40 dark:text-red-300 dark:border-red-900"
  end
end
