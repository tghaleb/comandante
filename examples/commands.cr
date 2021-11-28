module Prog2
  include Comandante::OptParserTypes

  module Commands
    class Eval < CommandAction
      def run(
        global_opts : OptionsHash,
        opts : OptionsHash,
        args : Array(String)
      ) : Nil
        Helper.debug_inspect global_opts
        Helper.debug_inspect opts
        Helper.debug_inspect args
        Helper.debug_inspect({test: 1 == 2})
        Helper.debug_inspect(["one", "two"])

        opts["src"].as(Array(String)).each do |f|
          File.open(f) do |io|
            "will read " + f
          end
        end
      end
    end

    class Export < CommandAction
      def run(
        global_opts : OptionsHash,
        opts : OptionsHash,
        args : Array(String)
      ) : Nil
        Helper.debug_inspect global_opts
        Helper.debug_inspect opts
        Helper.debug_inspect args
        args.each do |f|
          File.open(f) do |io|
            "will read " + f
          end
        end
      end
    end
  end
end
