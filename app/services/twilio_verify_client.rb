require "twilio-ruby"

# Wraps the Twilio Verify Service used for OTP login. Separate Twilio product
# from the Programmable Messaging account the Python side uses for SMS
# alerts, but shares the same Account SID/Auth Token.
class TwilioVerifyClient
  def self.client
    @client ||= Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
  end

  def self.service
    client.verify.v2.services(ENV.fetch("TWILIO_VERIFY_SERVICE_SID"))
  end

  def self.send_code(phone)
    service.verifications.create(to: phone, channel: "sms")
    true
  rescue Twilio::REST::TwilioError => e
    Rails.logger.warn("Twilio Verify send_code failed for #{phone}: #{e.message}")
    false
  end

  def self.check_code(phone, code)
    service.verification_checks.create(to: phone, code: code).status == "approved"
  rescue Twilio::REST::TwilioError => e
    Rails.logger.warn("Twilio Verify check_code failed for #{phone}: #{e.message}")
    false
  end
end
