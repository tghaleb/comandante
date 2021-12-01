require "colorize"
require "openssl/digest"
require "option_parser"
require "set"
require "time"
require "yaml"
require "json"
require "file_utils"
require "compress/gzip"
require "compress/zip"

module Comandante
  # Some helper functions
  module Helper
    # A from_yaml wrapper that exits/raises on failure
    #
    # Example
    #
    # ```
    # x = YamlTo(Array(Int32)).load("[1,2,3]", ":config")
    # ```
    module YamlTo(T)
      def self.load(s, context = "") : T
        begin
          T.from_yaml(s)
        rescue e
          if context == ""
            Cleaner.exit_failure(e.message.to_s)
          else
            Cleaner.exit_failure("in #{context}: " + e.message.to_s)
          end
        end
      end
    end

    # Prints an error message to STDERR
    def self.put_error(msg, pref = "Error: ")
      STDERR.puts("%s%s" % [pref, msg.colorize(:red)])
    end

    # Prints a message to STDERR if in verbose mode
    def self.put_verbose(msg)
      STDERR.puts(msg) if Cleaner.verbose
    end

    # Prints a debug message if `Cleaner` is in debug mode
    def self.put_debug(msg, pref = "Debug: ")
      if Cleaner.debug
        STDERR.puts("%s%s" % [pref.colorize(:cyan), msg])
      end
    end

    # Prints a colorized inspect of val if `Cleaner` is in debug mode
    #
    # Example:
    #
    # ```
    # debug_inspect(@opts, context: "@opts")
    # debug_inspect({test: x == y})
    # debug_inspect(["one", "two"])
    # ```
    def self.debug_inspect(val, context = "")
      val_s = val.pretty_inspect
        .gsub(/([{},\[\]])/) { |s| $1.colorize(:red).to_s }
        .gsub(" => ", " => ".colorize(:yellow))
        .gsub(/("([^"\\]|\\.)*")/) { |s| $1.colorize(:green).to_s }
        .gsub(/(\[0m)([a-z][\w\d_]*: )/) { |s| $1 + $2.colorize(:blue).to_s }

      if context != ""
        put_debug("[#{context.colorize(:blue)}] -> " + val_s)
      else
        put_debug(val_s)
      end
    end

    # Asserts a condition, depending on `Cleaner` will either exit with
    # message or raise an error
    #
    # Example:
    # ```
    # assert(value > 0, "Expecting a value > 0")
    # ```
    def self.assert(cond, msg) : Nil
      unless cond
        Comandante::Cleaner.exit_failure(msg)
      end
    end

    # Asserts that a file exists
    def self.assert_file(file) : Nil
      assert(File.file?(file), "Not a file '#{file}")
    end

    # Asserts that a directory exists
    def self.assert_directory(dir) : Nil
      assert(File.directory?(dir), "Not a directory '#{dir}")
    end

    # mkdir with verbose option
    def self.mkdir(dir : String, verbose = false)
      if verbose
        Dir.mkdir(dir)
        STDERR.puts(" created: " + dir)
      else
        Dir.mkdir(dir)
      end
    end

    # :nodoc:
    def self.file_digest(path, _digest) : String
      Helper.assert_file(path)
      obj = OpenSSL::Digest.new(_digest)
      obj.file(path)
      return obj.final.hexstring
    end

    # :nodoc:
    def self.string_digest(string, _digest) : String
      obj = OpenSSL::Digest.new(_digest)
      obj.update(string)
      return obj.final.hexstring
    end

    {% for name in ["md5", "sha1", "sha256", "sha512"] %}
      # Returns {{name.id}} digest for file
      def self.file_{{name.id}}sum(path) : String
        file_digest(path, {{name.upcase}})
      end

      # Returns {{name.id}} digest for string
      def self.string_{{name.id}}sum(path) : String
        string_digest(path, {{name.upcase}})
      end
    {% end %}

    # Writes String to a file
    def self.string_to_file(str, file) : Nil
      begin
        File.open(file, "w") do |f|
          f.puts(str)
        end
      end
    end

    # Parses yaml from file and fails with message
    def self.read_yaml(file : String) : YAML::Any
      begin
        return Helper.parse_yaml(File.read(file), file)
      rescue e
        STDERR.puts(e.message)
        Cleaner.exit_failure("YAML reading failed in '#{file}'")
        return Nil.as(YAML::Any)
      end
    end

    # Parses yaml string and fails with message,
    # *context* is used in error messages
    def self.parse_yaml(str, context = "") : YAML::Any
      begin
        result = YAML.parse(str)
        if result == nil
          raise "Parse returned nil"
        end

        return result
      rescue e
        STDERR.puts(e.message)
        if context != ""
          Cleaner.exit_failure("YAML parse failed in '#{context}'")
        else
          Cleaner.exit_failure("YAML parse failed.")
        end
        return Nil.as(YAML::Any)
      end
    end

    # Reads gziped file line by line
    #
    # ```
    # read_gzip(path) { |line| puts line }
    # ```
    def self.read_gzip(path, &block) : Nil
      Helper.assert_file(path)
      File.open(path) do |io|
        Compress::Gzip::Reader.open(io) do |dio|
          line = dio.gets
          while !line.nil?
            yield line
            line = dio.gets
          end
        end
      end
    end

    # Reads gziped file into a string
    def self.read_gzip(path) : String
      str = ""
      Helper.assert_file(path)
      File.open(path) do |io|
        str = Compress::Gzip::Reader.open(io) do |dio|
          dio.gets_to_end
        end
      end
      return str
    end

    # Writes gziped file from a string
    def self.write_gzip(str, path) : Nil
      File.open(path, "w") do |io|
        Compress::Gzip::Writer.open(io) do |dio|
          dio.print str
        end
      end
    end

    # Runs a command using system and raises if command fails
    def self.run(cmd, args, msg = "cmd failed") : Nil
      system(cmd, args: args)
      unless $?.success?
        raise msg
      end
      return
    end

    # Timer for a block of commands, prints time at the end
    # Examples
    #
    # ```
    # timer { do_something }
    # ```
    def self.timer
      elapsed = Time.measure do
        yield
      end
      STDERR.puts "\nRun took  #{elapsed}"
    end
  end
end
