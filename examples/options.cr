module Prog2
  module Options
    class DebugAction < OptionAction
      def run(
        parser : OptParser,
        id : String,
        value : OptionValue
      ) : OptionValue
        Comandante::Cleaner.debug = true
        value
      end
    end

    VERBOSE_OPT = OptionConfig.new(
      name: "verbose",
      short: "v",
      option_type: OptionStyle::RepeatingSwitch,
      label: "verbosity level."
    )

    DEBUG_OPT = OptionConfig.new(
      name: "debug",
      short: "D",
      label: "debug mode.",
      action: DebugAction.new
    )

    LIMIT = OptionConfig.new(
      name: "limit",
      short: "l",
      label: "LIMIT for selection.",
      option_type: OptionStyle::Option,
      argument_string: "NUMBER",
      default: "100"
    )

    EVAL_OPTS = CommandConfig.new(
      name: "eval",
      label: "Evaluates some sources.",
      description: <<-E.to_s,
                Will evaluate something.
                And can accept repeating --src options
    
                Example:
                  #{NAME} eval --src one --src two
                E
      action: Commands::Eval.new,
      arguments_range: 0..0,
      options: [
        OptionConfig.new(
          name: "src",
          short: "s",
          label: "src of file(s) to eval.",
          argument_string: "FILE",
          option_type: OptionStyle::RepeatingOption,
        ),
      ],
    )

    CONVERT_OPTS = CommandConfig.new(
      name: "convert",
      label: "Converts to Some format.",
      description: <<-E.to_s,
         EXAMPLES 

           #{NAME} export --svg FILE
         E

      action: Commands::Export.new,
      arguments_range: 1..MAX_ARGS,
      arguments_string: "FILE ...",
      options: [
        OptionConfig.new(
          name: "svg",
          short: "s",
          label: "Converts to svg.",
        ),
        LIMIT,
      ],
    )
  end
end
