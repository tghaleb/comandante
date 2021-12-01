module Comandante
  module Cleaner
    extend self

    # Failure Mode types
    enum FailureMode
      EXIT
      EXCEPTION
    end

    alias SimpleProc = Proc(Nil)
    alias ArraySimpleProc = Array(SimpleProc)

    @@debug = false
    @@verbose = false
    @@cleanup_actions = ArraySimpleProc.new
    @@failure_behavior = FailureMode::EXIT
    @@tempfiles = Array(File).new
    @@tempdirs = Array(Dir).new

    # The desired failure_behavior, see `FailureMode`
    class_property failure_behavior

    class_property verbose

    # Debug Mode, you can use an action to set this with a global --debug
    # option
    class_property debug

    # Create a tempdir that will be removed on exit as long as you are
    # running inside a `run` block
    def tempdir(name = File.tempname) : Dir
      Dir.mkdir(name)
      tmp = Dir.new(name)
      @@tempdirs << tmp
      return tmp
    end

    # Create a tempdir that will be removed on exit from block
    def tempdir(name = File.tempname, &block) : Nil
      Dir.mkdir(name)
      tmp = Dir.new(name)
      # in case we fail before returning
      @@tempdirs << tmp
      yield name
      Dir.delete(tmp.path) if File.directory? tmp.path
      @@tempdirs.delete_at(-1)
    end

    # Create a tempfile that will be removed on exit as long as you are
    # running inside a `run` block
    def tempfile : File
      tmp = File.tempfile
      @@tempfiles << tmp
      return tmp
    end

    # Create a tempfile that will be removed on exit from block
    def tempfile(&block) : Nil
      tmp = File.tempfile
      @@tempfiles << tmp
      yield tmp.path
      tmp.delete if File.file? tmp.path
      @@tempfiles.delete_at(-1)
    end

    # Register a cleanup proc to be executed on exit from Cleanup::run
    # block.
    #
    # Example:
    #
    # ```
    # register ->{ my_cleaner; puts "cleanup done!" }
    # ```
    def register(proc : SimpleProc) : Nil
      @@cleanup_actions << proc
    end

    # Runs cleanup manually before end of block or from outside it.
    # will run user cleanup procs first, then remove any tempfiles or
    # tempdirs.
    def cleanup : Nil
      @@cleanup_actions.each do |proc|
        proc.call
      end
      @@tempfiles.reverse.each_with_index do |file, i|
        if File.exists?(file.path)
          file.delete
          # don't delete in case of being used early and file
          # becomes missing
          # @@tempfiles.delete_at(i)
        end
      end
      @@tempdirs.reverse.each_with_index do |dir, i|
        if Dir.exists?(dir.path)
          Dir.delete(dir.path)
          # @@tempdirs.delete_at(i)
        end
      end
    end

    # Will exit or raise exception with a message in accordance with
    # `failure_behavior`. Will run cleanup first.
    def exit_failure(msg : String, status = 1) : Nil
      cleanup

      if @@failure_behavior == FailureMode::EXIT
        STDERR.puts(("Error: " + msg).colorize(:red))
        exit status
      else
        raise Exception.new(msg)
      end
    end

    # Will exit with a message. Will run cleanup first.
    def exit_success(msg : String = "", status = 0) : Nil
      cleanup
      STDERR.puts(msg) if msg != ""
      exit status
    end

    # Runs a block with cleanup afterwards.
    # You should wrap your `app.run` inside
    #
    # Examples:
    #
    # ```
    # Cleaner.run do
    #   app.run
    # end
    # ```
    #
    # Will capture exceptions and run user cleanup function at end of
    # block.
    #
    def run(&block) : Nil
      # Just to avoid failures on pipes
      Signal::PIPE.trap do
        Comandante::Cleaner.exit_success
      end

      # It seems this works most of the time
      Signal::INT.trap do
        STDERR.puts "Interrupted"
        Comandante::Cleaner.exit_success
      end

      begin
        yield
      rescue e
        if @@debug
          puts e.formatted_backtrace
        end
        exit_failure(e.message.to_s)
      end
      exit_success
    end
  end
end
