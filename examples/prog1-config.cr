require "../src/comandante"
require "../src/comandante/config_singleton"

module Prog1
  include Comandante

  class Config < ConfigSingleton
    # if your config is nested, you need to define sub config types
    sub_config_type(URLConfig) do
      scheme : String = "https"
      no_proxy : Bool = false
    end

    # config_type is used to configure your top Config type and add accessors
    config_type(ServerConfig) do
      root_dir : String = "/srv/http/cache"
      listen : String = "127.0.0.1"
      port : Int32 = 8080
      # This uses a type you've alread defined
      urls : Hash(String, URLConfig) = Hash(String, URLConfig).new
    end

    # You can use something like this to validate config
    def self.validate
      self.urls.each do |k, v|
        if v.scheme != "http" && v.scheme != "https"
          self.exit_error("bad scheme #{v}")
        end
      end
    end
  end

  class App
    NAME  = "prog1"
    LABEL = "Config test"
    DESC  = "And does something else"

    def initialize
      @opts = OptParser.new(NAME, LABEL, DESC, arguments_string: "FILE", arguments_range: 1..1)

      @opts.append_option(OptParser::OptionConfig.new(
        name: "debug",
        label: "debug mode",
        simple_action: OptParser::OptProc.new { |v| Cleaner.debug = v.as(Bool) }
      ))
    end

    def run
      Comandante::Cleaner.run do
        @opts.parse

        # To load yaml config file
        Config.load_config(@opts.args[0])

        # To validate
        Config.validate

        # To dump to yaml
        puts Config.to_yaml
        puts Config.root_dir
        puts Config.listen
      end
    end
  end

  App.new.run
end
