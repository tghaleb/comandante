require "./spec_helper"

include Comandante

describe Comandante::Bits do
  it "store_as_int() and store_as_uint() should work" do
    x = 5.to_u32
    y = UInt32::MAX
    z = UInt64::MAX

    i = Comandante::Bits.store_as_int(x)
    j = Comandante::Bits.store_as_int(y)
    k = Comandante::Bits.store_as_int(z)

    Comandante::Bits.store_as_uint(i).should eq(x)
    Comandante::Bits.store_as_uint(j).should eq(y)
    Comandante::Bits.store_as_uint(k).should eq(z)
  end

  it "bit_set?() should work" do
    x = 1.to_u32
    y = UInt32::MAX - 1
    z = UInt64::MAX - 1

    Comandante::Bits.bit_set?(0, x).should eq(true)
    Comandante::Bits.bit_set?(0, y).should eq(false)

    Comandante::Bits.bit_set?(0, z).should eq(false)
    Comandante::Bits.bit_set?(63, z).should eq(true)
  end

  it "popcount_bits() should work" do
    count = 0

    x = 1.to_u32
    y = UInt32::MAX - 1
    z = UInt64::MAX - 1

    Comandante::Bits.popcount_bits(x, 0, 1).should eq(1)
    Comandante::Bits.popcount_bits(x, 0, 0).should eq(0)
    Comandante::Bits.popcount_bits(y, 0, 32).should eq(31)
    Comandante::Bits.popcount_bits(y, 2, 31).should eq(30)

    Comandante::Bits.popcount_bits(z, 4, 64).should eq(60)
  end

  it "loop_over_bits() should work" do
    count = 0
    total = 0

    x = 3.to_u32

    Comandante::Bits.loop_over_bits(x) do |i|
      count += 1 if Bits.bit_set?(i, x)
      total += 1
    end
    count.should eq(2)
    total.should eq(32)

    count = 0
    total = 0

    x = 3.to_u64
    Comandante::Bits.loop_over_bits(x) do |i|
      total += 1
      count += 1 if Bits.bit_set?(i, x)
    end
    count.should eq(2)
    total.should eq(64)
  end

  it "loop_over_set_bits() should work" do
    count = 0

    x = 1.to_u32
    y = UInt32::MAX - 1

    Comandante::Bits.loop_over_set_bits(x) { |i| count += 1 }
    count.should eq(1)

    count = 0

    Comandante::Bits.loop_over_set_bits(y) { |i| count += 1 }
    count.should eq(31)
  end

  it "bits_to_string() should work for int32" do
    count = 0

    x = 1.to_i
    y = Int32::MAX - 1
    xs = ("0" * 31) + "1"
    ys = "0" + ("1" * 30) + "0"

    Comandante::Bits.bits_to_string(x).should eq(xs)
    Comandante::Bits.bits_to_string(y).should eq(ys)

    y = -1.to_i
    #    ys = ("1" * 31) + "1"
    ys = ("1" * 32)

    Comandante::Bits.bits_to_string(y).should eq(ys)
  end

  it "bits_to_string() should work for uint32" do
    count = 0

    x = 1.to_u32
    y = UInt32::MAX - 1
    xs = ("0" * 31) + "1"
    ys = ("1" * 31) + "0"

    Comandante::Bits.bits_to_string(x).should eq(xs)
    Comandante::Bits.bits_to_string(y).should eq(ys)
  end

  it "set_bits() should work for uint32" do
    count = 0

    z = 0.to_u32
    x = 1.to_u32
    y = UInt32::MAX - 1

    Comandante::Bits.set_bits(z, [0]).should eq(1)
    Comandante::Bits.set_bits(z, [1]).should eq(2)
    Comandante::Bits.set_bits(z, [1, 2]).should eq(6)
    Comandante::Bits.set_bits(x, [0, 1]).should eq(3)
  end
  it "set_bits() should work for uint64" do
    count = 0

    z = 0.to_u64
    x = 1.to_u64
    y = UInt64::MAX - 1

    Comandante::Bits.set_bits(z, [0]).should eq(1)
    Comandante::Bits.set_bits(z, [1]).should eq(2)
    Comandante::Bits.set_bits(z, [1, 2]).should eq(6)
    Comandante::Bits.set_bits(x, [0, 1]).should eq(3)
  end
  it "get_bits() should work for uint64" do
    count = 0

    x = 3.to_u64
    y = 3.to_u32

    Comandante::Bits.get_bits(x, 0, 1).should eq(1)
    Comandante::Bits.get_bits(x, 0, 2).should eq(3)
    Comandante::Bits.get_bits(x, 1, 1).should eq(1)
    Comandante::Bits.get_bits(x, 1, 2).should eq(1)

    Comandante::Bits.get_bits(y, 0, 1).should eq(1)
    Comandante::Bits.get_bits(y, 0, 2).should eq(3)
  end
end
