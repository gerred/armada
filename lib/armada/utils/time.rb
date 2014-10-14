class Time
  def self.seconds_to_string(s)
    # d = days, h = hours, m = minutes, s = seconds
    m = (s / 60).floor
    s = s % 60
    h = (m / 60).floor
    m = m % 60
    d = (h / 24).floor
    h = h % 24

    output = "#{s} second#{Time.pluralize(s)}" if (s > 0)
    output = "#{m} minute#{Time.pluralize(m)}, #{s} second#{Time.pluralize(s)}" if (m > 0)
    output = "#{h} hour#{Time.pluralize(h)}, #{m} minute#{Time.pluralize(m)}, #{s} second#{Time.pluralize(s)}" if (h > 0)
    output = "#{d} day#{Time.pluralize(d)}, #{h} hour#{Time.pluralize(h)}, #{m} minute#{Time.pluralize(m)}, #{s} second#{Time.pluralize(s)}" if (d > 0)

    return output
  end

  def self.pluralize number
    return "s" unless number == 1
    return ""
  end
end
