class Exception
  # Adds a colorized backtrace to exceptions
  def formatted_backtrace : String
    result = Array(String).new
    backtrace.each do |x|
      parts = x.split(" in ")
      if parts.size == 2
        location = parts[0].gsub(/^(.+):(\d+):(\d+)$/) do |s|
          $1.colorize(:cyan).to_s + ":".colorize(:red).to_s +
            $2 + ":".colorize(:red).to_s +
            $3
        end
        result << location + " in ".colorize(:cyan).to_s +
                  parts[1].colorize(:yellow).to_s
      else
        result << x.colorize(:yellow).to_s
      end
    end
    return result.join("\n")
  end
end
