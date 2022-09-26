require "yaml"
require "./singleton"

module Comandante
  # A base file for data used by `ConfigSingleton`
  class ConfigData
    include YAML::Serializable
    include YAML::Serializable::Strict

    def initialize
    end
  end

  # Create your config class from this
  #
  # Example
  #
  # ```
  #    class Config < ConfigSingleton
  #      config_type(MyConfig) do
  #        name : String = "foo"
  #        age : Int32 = 150
  #      end
  # ```
  abstract class ConfigSingleton < Singleton
    include Comandante

    macro config_type(klass, &block)
      class {{klass}} < ConfigData
        {% for expr in yield.expressions %}
        {% if expr.is_a?(TypeDeclaration) %}
          property {{expr}}
        {% else %}
          {{expr}}
        {% end %}
        {% end %}
      end

      @config: {{klass}}
      getter :config

      # Initialize from a yaml file or just from defaults.
      private def initialize(file = "")
        if file != ""
          Helper.assert_file(file)
          @config = Helper::YamlTo({{klass}}).load(File.read(file))
        else
          @config = {{klass}}.new
        end
  
        Comandante::Helper.debug_inspect(@config)
      end

        {% for expr in yield.expressions %}
        {% if expr.is_a?(TypeDeclaration) %}
          def {{expr.var}}
            return @config.{{expr.var}}
          end
          def {{expr.var}}=(val)
              @config.{{expr.var}} = val
          end
          def self.{{expr.var}}
              return self.instance.{{expr.var}}
          end
          def self.{{expr.var}}=(val)
              self.instance.{{expr.var}}= val 
          end
        {% end %}
      {% end %}
    end

    def self.dump_yaml
      puts self.instance.config.to_yaml
    end

    def self.validate
      _validate
    end

    private def self.exit_error(msg)
      Comandante::Cleaner.exit_failure("config error: " + msg)
    end
  end
end
