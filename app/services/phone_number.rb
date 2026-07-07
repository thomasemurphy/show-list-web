# Normalizes user-entered phone numbers to E.164, matching the format the
# Firestore users/{phone} doc ID uses on both sides of the system.
module PhoneNumber
  def self.normalize(input)
    digits = input.to_s.gsub(/\D/, "")
    case digits.length
    when 10 then "+1#{digits}"
    when 11 then digits.start_with?("1") ? "+#{digits}" : nil
    else nil
    end
  end
end
