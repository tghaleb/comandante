module Comandante
  abstract class Singleton
    private def initialize
    end

    def self.instance(*args)
      @@instance ||= new(*args)
    end
  end
end
