module Comandante
  class OptParser
    include Comandante::OptParserTypes

    # TODO: cleanups for this file
    # :nodoc:
    ERROR_MSGS = {
      invalid_option:        "invalid option '%s'!",
      bad_command:           "bad sub_command '%s'!",
      wrong_argument_count:  "wrong argument count!",
      option_requires_value: "option --%s requires a value",
    }

    # ID for the main command, used internally
    ROOT_ID = "/"

    # :nodoc:
    class HelpAction < OptionAction
      def run(parser : OptParser, id : String, value : OptionValue) : OptionValue
        parser.print_help(id)
        exit 0
        value
      end
    end

    # :nodoc:
    DEFAULT_HELP_OPT = OptionConfig.new(
      name: "help",
      short: "h",
      label: "prints this help and exits.",
      action: HelpAction.new
    )

    @auto_help = true
    @max_width = 78
    @commands_str = "COMMANDS"
    @options_str = "OPTIONS"

    @args = Array(String).new
    @options = Hash(String, OptionsHash).new

    @user_options = Hash(String, Array(OptionConfig)).new
    @user_commands = Array(CommandConfig).new
    @commands_lookup = Hash(String, Int32).new
    @short_option_lookup = Hash(String, Hash(String, Int32)).new
    @long_option_lookup = Hash(String, Hash(String, Int32)).new

    # Controls to add or not to add a help option to command+subcommands
    property auto_help

    # Controls Maximum text width
    property max_width

    # Arguments Parsed
    getter args

    # Options Parsed
    def options(id = ROOT_ID)
      @options[id]
    end

    # The header to user for subcommands (defaults are usually fine)
    property commands_str

    # The header to use for options (defaults are usually fine)
    property options_str

    # Asserts argument count is in range, used internally, no
    # need to call this directly
    def self.assert_arg_count(args : Array(String), range : Range(Int32, Int32))
      unless range.includes? args.size
        Cleaner.exit_failure(ERROR_MSGS[:wrong_argument_count])
      end
    end

    # Asserts option has a value set or a default, used internally, no
    # need to call this directly
    def self.assert_option_value(opt, value)
      if value == ""
        Cleaner.exit_failure(ERROR_MSGS[:option_requires_value] % opt)
      end
    end

    # Creates the parser for the program. At lease a *name* and *label*
    # are required.
    #
    # Examples:
    #
    # For a simple program that will not use subcommands, and accepts 1 argument
    #
    # ```
    # opts = OptParser.new(NAME, LABEL, DESC,
    #   argument_string: "FILE",
    #   argument_range: 1..1)
    # ```
    #
    # For a program that will have subcommands
    #
    # ```
    # opts = OptParser.new(NAME, LABEL, DESC)
    # ```
    #
    def initialize(
      name,
      label,
      description = "",
      arguments_string = "",
      arguments_range = 0..MAX_ARGS
    )
      append(
        CommandConfig.new(
          _id: "/",
          name: name,
          label: label,
          description: description,
          arguments_string: arguments_string,
          arguments_range: arguments_range,
        )
      )
    end

    # Appends configuration for an option, *id* is the name/id of the
    # subcommand, when not given option is added to the main/root command.
    #
    # Examples:
    #
    # Adding to main command
    #
    # ```
    # opts.append_option(DEBUG_OPT)
    # ```
    # where DEBUG_OPT is an `OptParserTypes::OptionConfig`
    #
    # Although you can also use this method to add options to
    # subcommands, prefered way is to use `append` and configure
    # subcommands with all options that way.
    def append_option(opt : OptionConfig, id = ROOT_ID)
      @user_options[id] << opt

      # initialize once
      unless @short_option_lookup.has_key? id
        @short_option_lookup[id] = Hash(String, Int32).new
        @long_option_lookup[id] = Hash(String, Int32).new
      end

      @long_option_lookup[id][opt.name] = @user_options[id].size - 1

      if opt.short != ""
        @short_option_lookup[id][opt.short] = @user_options[id].size - 1
      end
    end

    # Appends Configuration for a subcommand, including its options.
    #
    # Examples:
    #
    # Adding a subcommand
    #
    # ```
    # opts.append(EVAL_OPTS)
    # ```
    # where EVAL_OPTS is a `OptParserTypes::CommandConfig`
    #
    def append(cmd : CommandConfig)
      @user_commands << cmd
      @user_options[cmd.id] = Array(OptionConfig).new
      @commands_lookup[cmd.id] = (@user_commands.size - 1)

      if cmd.options.size != 0
        cmd.options.each do |x|
          append_option(x, id: cmd.id)
        end
      end
    end

    # Do the actual parsing, called after all subcommands and options
    # are added to `OptParser` object.
    # Will call any action associated with subcommands and options
    # If you have no subcommands then you'll probably want to call
    # `.options` and `.args` to get the options and arguments
    # passed to the program.
    def parse(args = ARGV, id = ROOT_ID)
      add_auto_help
      @args = parser(args, id)
      if @args.size != 0 && commands_defined?
        cmd = @args.shift
        if command? cmd
          @args = parser(@args, cmd)
        else
          Cleaner.exit_failure(ERROR_MSGS[:bad_command] % cmd)
        end
      end
    end

    # Is called automatically but just in case you want to call it
    # manually
    def print_help(id = ROOT_ID)
      puts build_help(id)
    end

    # Tests if any commands have been defined
    private def commands_defined?
      return @commands_lookup.size > 1
    end

    # Adds auto help
    private def add_auto_help
      if @auto_help
        @commands_lookup.each_key do |id|
          append_option(DEFAULT_HELP_OPT, id)
        end
      end
    end

    # Builds the help string
    private def build_help(id)
      result = Array(String).new

      result << build_usage_section(id)
      result << build_commands_section(id)
      result << build_options_section(id)

      result.join("")
    end

    private def _label(id)
      @user_commands[@commands_lookup[id]].label
    end

    private def _name(id)
      @user_commands[@commands_lookup[id]].name
    end

    private def _arguments_string(id)
      @user_commands[@commands_lookup[id]].arguments_string
    end

    private def _description(id)
      @user_commands[@commands_lookup[id]].description
    end

    # Sets to user defaults of sensible ones for type
    private def set_option_defaults(id) : Nil
      @long_option_lookup[id].each_key do |name|
        opt = long_option_config(id, name)
        if opt.option_type == OptionStyle::RepeatingOption
          _set_option_value(id, opt, Array(String).new, internal: true)
        elsif opt.option_type == OptionStyle::Option
          _set_option_value(id, opt, opt.default, internal: true)
        elsif opt.option_type == OptionStyle::Switch
          if opt.default.is_a? Bool
            _set_option_value(id, opt, opt.default, internal: true)
          else
            _set_option_value(id, opt, false, internal: true)
          end
        else
          # RepeatingSwitch
          if opt.default.is_a? Int32
            _set_option_value(id, opt, opt.default, internal: true)
          else
            _set_option_value(id, opt, 0, internal: true)
          end
        end
      end
    end

    private def build_commands_section(id) : String
      return "" if id != ROOT_ID
      return "" unless commands_defined?
      result = Array(String).new

      result << @commands_str + "\n"
      @user_commands.each do |cmd|
        next if cmd.id == ROOT_ID
        result << "  %-10s %s\n" % [cmd.name, cmd.label]
      end
      return result.join("") + "\n"
    end

    private def build_options_section(id) : String
      return "" if @user_options[id].size == 0

      result = Array(String).new
      tmp = Array(String).new

      result << @options_str + "\n"
      col_width = 0
      @user_options[id].each do |opt|
        arg = ""
        if opt.option_type == OptionStyle::Option || opt.option_type ==
             OptionStyle::RepeatingOption
          if opt.default.to_s != ""
            arg = " " + opt.default.to_s
          else
            arg = " " + opt.argument_string
          end
        end

        if opt.short != ""
          tmp << "  -%s,--%-14s" % [opt.short, opt.name + arg]
        else
          tmp << "     --%-14s" % [opt.name + arg]
        end
        width = tmp[-1].size
        col_width = width if width > col_width
      end

      col2_width = @max_width - col_width + 2

      @user_options[id].each_index do |i|
        opt = @user_options[id][i]
        result << tmp[i] + " "*(col_width - tmp[i].size + 2) +
                  word_wrap(opt.label, indent: col_width + 2, width: col2_width) + "\n"
      end

      return result.join("") + "\n"
    end

    private def build_usage_section(id) : String
      result = Array(String).new

      arg_string = ""

      if _arguments_string(id) != ""
        arg_string = " " + _arguments_string(id)
      end

      if @user_commands.size <= 1
        # no subcommands
        result << "Usage: #{_name(ROOT_ID)} [#{@options_str}]#{arg_string}\n"
      else
        if id == ROOT_ID
          # Top help
          result << "Usage: #{_name(ROOT_ID)} #{@commands_str} [#{@options_str}]\n"
        else
          # Command help
          result << "Usage: #{_name(ROOT_ID)} #{_name(id)} [#{@options_str}]#{arg_string}\n"
        end
      end
      result << "\n"
      result << "#{_label(id)}\n"

      if _description(id) != ""
        result << "\n"
        result << "#{_description(id)}\n"
      end

      return result.join("") + "\n"
    end

    private def _set_option_value(id, opt_config, value, internal = false)
      if internal
        @options[id][opt_config.name] = value
      else
        @options[id][opt_config.name] = opt_config.action.run(
          parser: self,
          id: id,
          value: value)

        opt_config.simple_action.call(value)
      end
    end

    private def register_option(id, opt_config, index, next_arg = "") : Int32
      if opt_config.option_type == OptionStyle::Switch
        _set_option_value(id, opt_config, true)
      elsif opt_config.option_type == OptionStyle::Option
        OptParser.assert_option_value(opt_config.name, next_arg)
        _set_option_value(id, opt_config, next_arg)
        index += 1
      elsif opt_config.option_type == OptionStyle::RepeatingSwitch
        unless @options[id].has_key? opt_config.name
          @options[id][opt_config.name] = 0
        end
        _set_option_value(id, opt_config,
          @options[id][opt_config.name].as(Int32) + 1)
      else
        unless @options[id].has_key? opt_config.name
          @options[id][opt_config.name] = Array(String).new
        end
        OptParser.assert_option_value(opt_config.name, next_arg)

        @options[id][opt_config.name].as(Array(String)) << next_arg
        index += 1
      end
      return index
    end

    private def long_option_config(id, name)
      @user_options[id][@long_option_lookup[id][name]]
    end

    private def short_option_config(id, name)
      @user_options[id][@short_option_lookup[id][name]]
    end

    private def long_opt(id, args, index) : Int32
      arg = args[index]
      next_arg = ""

      match = /^--([a-zA-Z]+[a-zA-Z0-9-]+)(=?.*)/.match(arg)

      if index < (args.size - 1)
        next_arg = args[index + 1]
      end

      if match
        opt = match[1]

        if @long_option_lookup[id].has_key? opt
          if match[2] != ""
            next_arg = match[2].sub(/^=/, "")
            # index will be incremented later
            index = index - 1
          end

          opt_config = @user_options[id][@long_option_lookup[id][opt]]
          index = register_option(
            id: id,
            opt_config: opt_config,
            index: index,
            next_arg: next_arg
          )
        else
          Cleaner.exit_failure(ERROR_MSGS[:invalid_option] % opt)
        end
      end
      return index
    end

    private def command_conf(id)
      return @user_commands[@commands_lookup[id]]
    end

    private def short_opt(id, args, index) : Int32
      # make a function? takes a regex
      arg = args[index]
      next_arg = ""

      match = /^-([a-zA-Z])(.*)/.match(arg)

      if index < (args.size - 1)
        next_arg = args[index + 1]
      end

      if match
        opt = match[1]

        if @short_option_lookup[id].has_key? opt
          opt_config = @user_options[id][@short_option_lookup[id][opt]]
          if match[2] != ""
            if opt_config.option_type == OptionStyle::Option ||
               opt_config.option_type == OptionStyle::RepeatingOption
              next_arg = match[2].sub(/^=/, "")
            else
              next_opt = match[2][0].to_s

              if @short_option_lookup[id].has_key? next_opt
                args[index] = "-" + args[index][2..-1]
              else
                Cleaner.exit_failure(ERROR_MSGS[:invalid_option] % [
                  opt + match[2],
                ])
              end
            end

            # index will be incremented later
            index -= 1
          end

          index = register_option(
            id: id,
            opt_config: opt_config,
            index: index,
            next_arg: next_arg
          )
        else
          Cleaner.exit_failure(ERROR_MSGS[:invalid_option] % opt)
        end
      end
      return index
    end

    private def short_opt?(id, arg)
      arg =~ /^-[a-zA-Z]/
    end

    private def long_opt?(id, arg)
      arg =~ /^--[a-zA-Z]+/
    end

    private def command?(arg)
      return @commands_lookup.has_key? arg
    end

    private def word_wrap(text, indent = 0, width = 40)
      return text if width <= 0
      text.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n" + " " * indent).strip
    end

    private def parser(args = ARGV, id = ROOT_ID)
      unless @options.has_key? id
        @options[id] = OptionsHash.new
      end

      set_option_defaults(id)
      @args = Array(String).new
      #      _args = Array(String).new

      i = 0
      while i < args.size
        x = args[i]
        if long_opt?(id, x)
          i = long_opt(id, args, i)
          i += 1
        elsif short_opt?(id, x)
          i = short_opt(id, args, i)
          i += 1
        else
          # arg
          if id == ROOT_ID && @commands_lookup.has_key? x
            # _args.concat(args[i..-1])
            @args.concat(args[i..-1])
            # @args = _args
            # return _args
            return @args
          else
            @args << x
            # _args << x
            i += 1
          end
        end
      end
      #      @args = _args
      OptParser.assert_arg_count(@args, command_conf(id).arguments_range)
      command_conf(id).action.run(@options[ROOT_ID], @options[id], @args)
      return @args
    end
  end
end
