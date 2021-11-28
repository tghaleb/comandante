module Comandante
  # Common Types used inside Comandante
  module OptParserTypes
    # Default maximum number of program argument, you can however set
    # any number in argument configuration range.
    MAX_ARGS = 256

    # Just in case an empty args array is needed
    EMPTY_ARGS = Array(String).new(size: 0, value: "")

    # Available Types for Options
    enum OptionStyle
      Switch
      Option
      RepeatingSwitch
      RepeatingOption
    end

    alias OptionValue = String | Bool | Int32 | Float64 | Array(String)
    alias OptionsHash = Hash(String, OptionValue)
    alias OptProc = Proc(OptParser::OptionValue, Nil)

    # A base class for Command Actions
    abstract class CommandAction
      @global_opts = OptionsHash.new
      @opts = OptionsHash.new
      @args = Array(String).new

      abstract def run(
        global_opts : OptionsHash,
        opts : OptionsHash,
        args : Array(String)
      ) : Nil
    end

    # A base class for Option Actions
    abstract class OptionAction
      abstract def run(
        parser : OptParser,
        id : String,
        value : OptionValue
      ) : OptionValue
    end

    # A Null Command Action
    class NullCommandAction < CommandAction
      def run(
        global_opts : OptionsHash,
        opts : OptionsHash,
        args : Array(String)
      ) : Nil
      end
    end

    # A Null Option Action
    class NullOptionAction < OptionAction
      def run(
        parser : OptParser,
        id : String,
        value : OptionValue
      ) : OptionValue
        value
      end
    end

    record OptionConfig,
      name : String, # is also id and becomes long --name
      label : String,
      short : String = "",
      option_type : OptionStyle = OptionStyle::Switch,
      default : OptionValue = "",
      argument_string : String = "ARG",
      simple_action : OptProc = ->(s : OptionValue) {},
      action : OptionAction = NullOptionAction.new

    record CommandConfig,
      name : String,
      label : String,
      description : String = "",
      arguments_string : String = "",
      arguments_range : Range(Int32, Int32) = 0..MAX_ARGS,
      action : CommandAction = NullCommandAction.new,
      options : Array(OptionConfig) = Array(OptionConfig).new,
      _id : String = "" do
      def id
        if _id == ""
          name
        else
          _id
        end
      end
    end
  end
end
