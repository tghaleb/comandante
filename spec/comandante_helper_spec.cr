require "./spec_helper"

include Comandante

describe Comandante::Helper do
  it "asserts() should work" do
    Cleaner.failure_behavior = Cleaner::FailureMode::EXCEPTION

    expect_raises(Exception, "failed") do
      Helper.assert(5 == 4, "failed")
    end
    Helper.assert(5 == 5, "")

    expect_raises(Exception, "failed") do
      Helper.assert(5 == 4, "failed")
    end

    Cleaner.tempfile do |temp|
      Helper.assert_file(temp)

      expect_raises(Exception, "Not a file") do
        Helper.assert_file(temp + "123")
      end

      expect_raises(Exception, "Not a directory") do
        Helper.assert_directory(temp + "123")
      end
    end
  end

  it "digests() should work" do
    s = "test"

    md5 = "098f6bcd4621d373cade4e832627b4f6"
    sha1 = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
    sha256 = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    sha512 = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff"

    Helper.string_md5sum(s).should eq(md5)
    Helper.string_sha1sum(s).should eq(sha1)
    Helper.string_sha256sum(s).should eq(sha256)
    Helper.string_sha512sum(s).should eq(sha512)

    Cleaner.tempfile do |temp|
      Helper.string_to_file(s, temp)
      Helper.file_md5sum(temp).size.should eq(md5.size)
      Helper.file_sha1sum(temp).size.should eq(sha1.size)
      Helper.file_sha256sum(temp).size.should eq(sha256.size)
      Helper.file_sha512sum(temp).size.should eq(sha512.size)
    end
  end

  it "gzip() writer/reader should work" do
    s = "test"
    Cleaner.tempfile do |temp|
      Helper.write_gzip(s, temp)
      Helper.read_gzip(temp).should eq(s)

      Helper.read_gzip(temp) do |line|
        line.should eq(s)
      end
    end
  end

  it "yaml() functions should work" do
    Cleaner.failure_behavior = Cleaner::FailureMode::EXCEPTION
    vals = ["one", "two"]

    vals2 = Helper::YamlTo(Array(String)).load(vals.inspect, "vals")
    vals.should eq(vals)

    expect_raises(Exception, "") do
      Helper::YamlTo(Array(String)).load("", "vals")
    end

    vals2 = Helper.parse_yaml(vals.inspect, "vals")
    vals2.as_a[0].should eq vals[0]

    expect_raises(Exception, "") do
      Helper.parse_yaml("", "vals").should eq(nil)
    end

    Cleaner.tempfile do |temp|
      Helper.string_to_file(vals.inspect, temp)
      vals2 = Helper.read_yaml(temp)
      vals2.should eq vals
    end
  end
end
