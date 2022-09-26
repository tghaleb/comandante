require "../src/comandante"
require "../src/comandante/config_singleton"

module Prog1
  include Comandante

  class Config < ConfigSingleton
    config_type(MyConfig) do
      name : String = "foo"
      age : Int32 = 150
    end

    private def self._validate
      if self.age > 200
        self.exit_error("bad agae #{self.age}")
      end
    end
  end

  class App
    def initialize
    end

    def run
      unless ARGV.size == 1
        STDERR.puts "E: need config.yaml"
      end

      Config.instance(ARGV[0])

      puts Config.dump_yaml
      puts Config.name
      puts Config.instance.name
      puts Config.age
      puts Config.instance.age
    end
  end

  App.new.run
end
