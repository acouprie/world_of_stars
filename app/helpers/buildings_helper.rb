module BuildingsHelper
  def building_name(type)
    I18n.t("buildings.types.#{type}", default: type.to_s.humanize)
  end

  def format_duration(seconds)
    seconds = seconds.to_i
    if seconds < 60
      "#{seconds} s"
    elsif seconds < 3600
      m = seconds / 60
      s = seconds % 60
      s > 0 ? "#{m} min #{s} s" : "#{m} min"
    else
      h = seconds / 3600
      m = (seconds % 3600) / 60
      m > 0 ? "#{h} h #{m} min" : "#{h} h"
    end
  end
end
