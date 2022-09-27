module Comandante
  module Macros
    # debug macro that doesn't get evaluated in :release mode
    macro debug(msg)
      {% unless flag? :release %}
        Comandante::Helper.put_debug({{msg}})
      {% end %}
    end

    macro debug(msg, context)
     {% unless flag? :release %}
        Comandante::Helper.put_debug({{msg}}, {{context}})
     {% end %}
    end

    # debug macro that doesn't get evaluated in :release mode
    macro debug_pretty(data)
      {% unless flag? :release %}
        Comandante::Helper.debug_inspect({{data}})
      {% end %}
    end

    macro debug_pretty(data, context)
     {% unless flag? :release %}
        Comandante::Helper.debug_inspect({{data}}, {{context}})
     {% end %}
    end
  end
end
