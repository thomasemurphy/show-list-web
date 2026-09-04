module ApplicationHelper
  # Flash entries that belong next to the control that produced them rather
  # than in the banner at the top of the page. Adding a band happens at the
  # bottom of the dashboard table, so its outcome is shown there — see
  # bands/_add_control — where the person who just clicked Add is looking.
  ANCHORED_FLASH_KEYS = %w[band_notice band_alert].freeze

  # The flash entries the layout's top-of-page banner should render.
  def page_flashes
    flash.to_hash.except(*ANCHORED_FLASH_KEYS)
  end

  # [style, message] for the add-a-band outcome, or nil. style matches the
  # layout's own vocabulary ("alert" is the red treatment).
  def band_flash
    if flash[:band_alert].present?
      [ "alert", flash[:band_alert] ]
    elsif flash[:band_notice].present?
      [ "notice", flash[:band_notice] ]
    end
  end

  # Tailwind classes for a flash of the given style, shared by the top-of-page
  # banner and the popover anchored to the Add band control so the two read as
  # the same kind of message.
  def flash_classes(style)
    if style == "alert"
      "bg-red-50 text-red-700 border-red-100 dark:bg-red-950/40 dark:text-red-300 dark:border-red-900"
    else
      "bg-green-50 text-green-700 border-green-100 dark:bg-green-950/40 dark:text-green-300 dark:border-green-900"
    end
  end
end
