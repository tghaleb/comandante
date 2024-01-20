require "yaml"
require "./macros"

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
  #
  # if you intend to use nested types derive them first from ConfigData
  #
  # ```
  #    class Config < ConfigSingleton
  #      class URLConfig < ConfigData
  #        getter scheme : String = "https"
  #        getter no_proxy : Bool = false
  #      end
  #
  #      config_type(MyConfig) do
  #        urls : Hash(String, URLConfig) = Hash(String, URLConfig).new
  #      end
  # ```
  abstract class ConfigSingleton
    include Comandante
    include Comandante::Macros

    private macro _properties(expressions)
      {% for expr in expressions %}
      {% if expr.is_a?(TypeDeclaration) %}
        _property {{expr.var}}
      {% end %}{% end %}
    end

    # setters and getters for @config.var on both class and object
    private macro _property(var)
      def {{var}}
        return @config.{{var}}
      end
      def {{var}}=(val)
          @config.{{var}} = val
      end
      def self.{{var}}
          return self.instance.{{var}}
      end
      def self.{{var}}=(val)
          self.instance.{{var}}= val
      end
    end

    private macro _def_config(klass)
      @config : {{klass}} = {{klass}}.new
      getter :config

      def load_config(file)
          Helper.assert_file(file)
          @config = Helper::YamlTo({{klass}}).load(File.read(file))

          debug_pretty(@config)
      end
    end

    # Seems that single property in a block is passed differently
    # at least for now so we treat it differently.
    private macro _single_property_config_type(klass, var, type, value)
      class {{klass}} < ConfigData
        property {{var}} : {{type}}  = {{value}}
      end
      _property {{var}}
    end

    private macro _multi_property_config_type(klass, &block)
      class {{klass}} < ConfigData
        {% for expr in yield.expressions %}
        {% if expr.is_a?(TypeDeclaration) %}
          property {{expr}}
        {% else %}
          {{expr}}
        {% end %}{% end %}
      end
      _properties({{yield.expressions}})
    end

    # defines a config type and accessors of its properties on the
    # singleton class as well as on @config, also defines a load_config
    macro config_type(klass, &block)
      as_singleton
      {% if yield.is_a?(TypeDeclaration) %}
          _single_property_config_type({{klass}}, {{yield.var}}, {{yield.type}}, {{yield.value}})
      {% else %}
       _multi_property_config_type({{klass}}) {{block}}
      {% end %}
      _def_config({{klass}})
    end

    # Used to load/read config file
    #
    # Example
    #
    # ```
    # Config.load_config(ARGV[0])
    # ```
    def self.load_config(file)
      instance.load_config(file)
    end

    private def self.exit_error(msg)
      Comandante::Cleaner.exit_failure("config error: " + msg)
    end
  end
end
