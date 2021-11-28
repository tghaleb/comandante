require "../src/comandante"
require "./commands"
require "./options"

module Prog2
  include Comandante

  NAME  = "prog2"
  LABEL = %q{
 __  __       ____
|  \/  |_   _|  _ \ _ __ ___   __ _
| |\/| | | | | |_) | '__/ _ \ / _` |
| |  | | |_| |  __/| | | (_) | (_| |
|_|  |_|\__, |_|   |_|  \___/ \__, |
        |___/                 |___/  }.gsub(/^\n/, "").colorize(:cyan).to_s + LABEL_TEXT

  LABEL_TEXT = "Example program 2"
  VERSION    = "0.0.1"

  class App
    include Options

    def parse_opts
      opts = OptParser.new(NAME, LABEL)

      opts.append_option(VERBOSE_OPT)
      opts.append_option(DEBUG_OPT)

      opts.append(EVAL_OPTS)
      opts.append(CONVERT_OPTS)

      opts.parse
    end

    def run
      Comandante::Cleaner.run do
        parse_opts
      end
    end
  end

  App.new.run
end
