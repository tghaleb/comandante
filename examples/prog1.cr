require "../src/comandante"

module Prog1
  include Comandante

  NAME    = "prog1"
  LABEL   = "Example program 1"
  VERSION = "0.0.1"

  class App
    def initialize
      @opts = OptParser.new(NAME, LABEL,
        arguments_string: "FILE",
        arguments_range: 1..1)

      @opts.append_option(OptParser::OptionConfig.new(
        name: "debug",
        label: "debug mode",
        simple_action: OptParser::OptProc.new { |v| Cleaner.debug = v.as(Bool) }
      ))
    end

    def run
      @opts.parse
      Helper.debug_inspect(@opts.args)
      Helper.debug_inspect(@opts.options)
    end
  end

  App.new.run
end
