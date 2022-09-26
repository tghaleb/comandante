# Comandante

A CLI toolkit including an option parser and some helper
commands to make life easier. 

## Features

- Easy to use command line [option parser][Comandante::OptParser].
- Supports four [option types][Comandante::OptParserTypes::OptionStyle]:
    - Switches
    - Options
    - Repeating Switches
    - Repeating Options
- Automatic addition of help (active by [default][Comandante::OptParser#auto_help]).
- User actions can be attached to commands/options.
- Argument count checking.
- Customizable modes of [failure][Comandante::Cleaner::FailureMode]: 
    - Exit with message
    - Raise exception
- A [cleaner][Comandante::Cleaner] which allows for custom cleanup functions on exits
  or exceptions.
- tempfiles and directories that will automatically be cleaned on
  exit.
- A [helper][Comandante::Helper] providing:
    - error messages
    - debugging messages
    - assertions
    - yaml reader/writer
    - gzip file reader/writer
    - and more ...
- Colorized backtrace messages for [exceptions][Exception].
- Helper functions for [bitwise operations][Comandante::Bits].

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  comandante:
    github: tghaleb/comandante
```

2. Run `shards install`

## Examples

In `Commandante` project directory:

```console
make examples
./examples/prog1 -h
./examples/prog2 --help
```

Take a look at the code in
[examples/](https://github.com/tghaleb/comandante/blob/main/examples/)
and optionally in
[spec/](https://github.com/tghaleb/comandante/blob/main/spec/).

## Usage

```crystal
require "comandante"
```

### OptParser

`OptParser` can be used to parse arguments for interfaces with simple
arguments as well as those that have sub commands. For a very basic CLI
create a new [OptParser][Comandante::OptParser.new].

```crystal
@opts = OptParser.new(NAME, LABEL,
  arguments_string: "FILE",
  arguments_range: 1..1)
```

*arguments_range* for argument count checking.

Add an option, unless you specify the option type
it is a [Swtich][Comandante::OptParserTypes::OptionStyle::Switch]

```crystal
@opts.append_option(
  OptParser::OptionConfig.new(
   name: "debug",
   label: "debug mode",
   simple_action: OptParser::OptProc.new { |v| Cleaner.debug = v.as(Bool) }
 ))
@opts.append_option(
  OptParser::OptionConfig.new(
   name: "verbose",
   label: "verbose mode",
   simple_action: OptParser::OptProc.new { |v| Cleaner.verbose = v.as(Bool) }
 ))

```

The *simple_action* takes a proc that sets debug mode. Another
option that you can use is *action* which takes a class
derived from [OptionAction][Comandante::OptParserTypes::OptionAction].
Use it when `simple_action` is not enough.

```crystal
@opts.parse

Helper.debug_inspect(@opts.args)
Helper.debug_inspect(@opts.options)
```

[debug_inspect][Comandante::Helper.debug_inspect] will display
debug messages if the user uses the `--debug` switch. 

For a full example take a look at [examples/](https://github.com/tghaleb/comandante/blob/main/examples/)

For subcommands you create a class derived from [CommandAction][Comandante::OptParserTypes::CommandAction].

```crystal
class Eval < CommandAction
  def run(
    global_opts : OptionsHash,
    opts : OptionsHash,
    args : Array(String)
  ) : Nil
    Helper.debug_inspect global_opts
    Helper.debug_inspect opts
    Helper.debug_inspect args
    opts["src"].as(Array(String)).each do |f|
      File.open(f) do |io|
        "will read " + f
      end
    end
  end
end
```

Create configuration for the sub command 

```crystal
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
```

Here the action is the command object. For the option *src* we are
using a [RepeatingOption][Comandante::OptParserTypes::OptionStyle::RepeatingOption].
Aappend the configuration to the parser.

```crystal
opts.append(EVAL_OPTS)
```

For a complete example take a look at [examples/](https://github.com/tghaleb/comandante/blob/main/examples/)


### Cleaner

You wrap your code in a [Cleaner.run][Comandante::Cleaner.run]

```crystal
Cleaner.run do |x|
  opts.parse
  tempfile = Cleaner.tempfile
  do_stuff(temfile)

  tempdir = Cleaner.tempdir
  do_stuff(tempdir)

  raise "something wrong happend"
end
```

[Cleaner.run][Comandante::Cleaner.run] will remove created tempfiles
and temp directories on exiting the block. It will also catch any raised
exceptions and exit printing the error message, or, if in debug mode,
it will print a colorized backtrace. 

For temp files and directories you will probably want to use a block, 
to make sure files are removed as soon as you're done with them.

```crystal
Cleaner.run do |x|
  Cleaner.tempfile do |file|
    # do something with file
  end
  # file will be removed
end
```

You can register cleanup procs that will be run on block exit, or when a
Cleaner explicit exit is called.

```crystal
Cleaner.register -> { puts "will do cleanups" }
```

In cases you want to exit with an error, or just exit cleanly, you can run

```crystal
if File.file? file
  Cleaner.exit_success
else
  Cleaner.exit_failure("Failed to create file")
end
```

Both will run a cleanup job before they exit, running any registered
cleaners in addition to removing tempfiles and temp directories.

### Helper

```crystal
# printing messages
Helper.debug_msg("Will print this in debug mode"
Helper.debug_inspect(@opts)
Helper.put_error("Something went wrong")
Helper.put_verbose("Creating files")

# running commands
Helper.run("touch newfile")

# asserts
Helper.assert(x < 5, "Not in range")
Helper.assert_file(file)
Helper.assert_directory(dir)

# reading files
@config = Helper.read_yaml(file)
@config = Helper.parse_yaml(str, context_str)

Helper.read_gzip(file) do |line|
  puts line
end

s = Helper.read_gzip(path)

# Create a directory with a verbose option
Helper.mkdir(dir, verbose: true)

# digests for files/strings
puts Helper.file_md5sum(path)
puts Helper.file_sha1sum(path)
puts Helper.string_sha256sum("test")
puts Helper.string_sha512sum("test")

# Times a job and prints time it took
Helper.timer {
 long_job
}
```

### Bits

```crystal
x = 5.to_u16
y = 12.to_u64

Bits.set_bits(x, [1, 3, 7, 8])

# test if a bit is set
do_something if Bits.bit_set?(3, y)

z = Bits.get_bits(y, from: 2, count 3)

z = Bits.popcount_bits(y, from: 1, count 3)

puts Bits.bits_to_string(y)

Bits.loop_over_set_bits(x) do |i|
  puts "bit #{i} is set"
end

# store int as uint and vice versa, for example if you want
# to save uints in an sqlite database.
m = bits.store_as_int(x)
u = bits.store_as_uint(m)
```

see [spec/](https://github.com/tghaleb/comandante/blob/main/spec/)

### Config

A [ConfigSingleton][Comandante::ConfigSingleton] that simplifies loading config from a `yaml` file. You use the included macro `config_type`, for example:

```crystal
  class Config < ConfigSingleton
    config_type(MyConfig) do
      name : String = "foo"
      age : Int32 = 150
    end
...
```

Which creates accessors on both the instance and on the `Config` module.
And you can pass a yaml config file to initialize the instance like so:

```crystal
Config.initialize("config.yaml")

puts Config.name
puts Config.instace.name
...
```

You can also add a validator for the config data,

```crystal
private def self._validate
  if self.age > 200
    self.exit_error("bad age #{self.age}")
  end
end
```

Which you can call by calling

```crystal
Config.validate
```
You can also create complex types that are classes just make sure to
derive your sub-classes from `ConfigData`. Nested types also work.

```crystal
class MyType < ConfigData 
end
```

Take a look at the code in [examples/](https://github.com/tghaleb/comandante/blob/main/examples/).



