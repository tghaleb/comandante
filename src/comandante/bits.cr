module Comandante
  # Some bitwise helper functions
  module Bits
    # Bit masks for every bit position for a UInt type
    BIT_MASKS = {
        8 => BitMasks(UInt8).get_masks,
       16 => BitMasks(UInt16).get_masks,
       32 => BitMasks(UInt32).get_masks,
       64 => BitMasks(UInt64).get_masks,
      128 => BitMasks(UInt128).get_masks,
    }

    # Masks for each size of UInt of 0,1, and MAX
    MASKS = {
        8 => {0.to_u8, 1.to_u8, UInt8::MAX},
       16 => {0.to_u16, 1.to_u16, UInt16::MAX},
       32 => {0.to_u32, 1.to_u32, UInt32::MAX},
       64 => {0.to_u64, 1.to_u64, UInt64::MAX},
      128 => {0.to_u128, 1.to_u128, UInt128::MAX},
    }

    # Creator of BitMasks for types
    module BitMasks(T)
      # Returns a Array of bit masks for each bit position for type
      def self.get_masks
        size = sizeof(T) * 8
        result = Array(T).new

        0.to_u32.upto(size - 1) do |i|
          result << (MASKS[size][1] << i).as(T)
        end
        return result
      end
    end

    # For conversion Int/Uint
    module Conversions(U, I)
      # Stores uint in int so we can serialize/store in places where uint
      # is not supported
      @[AlwaysInline]
      def self.store_as_int(n : U) : I
        pointerof(n).as(I*).value
      end

      # Stores int as uint for conversion serialize/store in places where uint
      # is not supported
      @[AlwaysInline]
      def self.store_as_uint(n : I) : U
        pointerof(n).as(U*).value
      end
    end

    # Returns the number of bits in a type
    macro type_bits(t)
       sizeof(typeof({{t}})) * 8
    end

    enum Indianess
      Big
      Little
    end

    {% for n in [8, 16, 32, 64, 128] %}
    # Stores uint in int so we can serialize/store in places where uint
    # is not supported
    @[AlwaysInline]
    def self.store_as_int(uint : UInt{{n}}) : Int{{n}}
      Conversions(UInt{{n}}, Int{{n}}).store_as_int(uint)
    end

    # Stores int as uint for conversion serialize/store in places where uint
    # is not supported
    @[AlwaysInline]
    def self.store_as_uint(int : Int{{n}}) : UInt{{n}}
      Conversions(UInt{{n}}, Int{{n}}).store_as_uint(int)
    end

    {% end %}

    # Sets bits on Uint Types
    #
    # Example
    #
    # To set bits 1,7 and 8
    #
    # ```
    # set_bits(x, [1, 7, 8]
    # ```
    @[AlwaysInline]
    def self.set_bits(uint, a : Array(Int32))
      size = type_bits(uint)
      a.each do |x|
        uint |= MASKS[size][1] << x
      end
      return uint
    end

    # Returns n bits from position
    #
    # Example
    #
    # To get a new uint with only count bits from given position
    #
    # ```
    # x = get_bits(u, from: 3, count 2]
    # ```
    @[AlwaysInline]
    def self.get_bits(uint, from : Int32, count : Int32)
      size = type_bits(uint)
      # no range checking
      return (uint >> from) & (MASKS[size][2] >> (size - count))
    end

    # Tests if a bit is set
    @[AlwaysInline]
    def self.bit_set?(pos, uint) : Bool
      size = type_bits(uint)
      (BIT_MASKS[size][pos] & uint) != 0
    end

    # Popcount n bits
    @[AlwaysInline]
    def self.popcount_bits(uint, from, count) : Int32
      size = type_bits(uint)

      return get_bits(uint, from, count).popcount.to_i32
    end

    # Loop over set bits of a bitmap (UInt types)
    @[AlwaysInline]
    def self.loop_over_set_bits(uint) : Nil
      i = 0
      n = 0
      size = type_bits(uint)

      while uint != 0
        break if i >= size

        # we only loop over set bits, better.
        n = uint.trailing_zeros_count

        if n == 0
          yield i
          uint = uint >> 1
        else
          i += n
          yield i
          uint = uint >> n + 1
        end
        i += 1
      end
    end

    # Loop over bits of a bitmap (UInt types)
    @[AlwaysInline]
    def self.loop_over_bits(uint) : Nil
      size = type_bits(uint)
      0.upto(size - 1) do |i|
        yield i
      end
    end

    # Returns binary representation as String
    # FIXME: probably need indianess here (lookup this on web)
    def self.bits_to_string(uint, indian = Indianess::Little) : String
      size = type_bits(uint)
      res = Array(String).new(size: size, value: "0")

      if indian == Indianess::Little
        Bits.loop_over_set_bits(uint) do |i|
          # left to right
          res[size - 1 - i] = "1"
        end
      else
        Bits.loop_over_set_bits(uint) do |i|
          # right to left
          res[i] = "1"
        end
      end
      return res.join("")
    end
  end
end
