require 'test/unit'
require 'apache_lookup'
require 'fileutils'
require 'rubygems'
require 'flexmock/test_unit'

class TestApacheLookup < Test::Unit::TestCase

  def setup
    @dir = "#{FileUtils.pwd}/test"
    # should make a local my_logs.log to work with so future runs of tests don't get clobbered by the last run
    FileUtils.cp("#{@dir}/my_logs.log", "#{@dir}/test_my_logs.log")

    # should delete the cache log if it exists to not clobber future tests.
    File.delete("#{@dir}/lookup_cache.log") if File.exists?("#{@dir}/lookup_cache.log")
  end

  def teardown
    File.delete("#{@dir}/test_my_logs.log") if File.exists?("#{@dir}/test_my_logs.log")
    File.delete("#{@dir}/test_my_logs.log.orig") if File.exists?("#{@dir}/test_my_logs.log.orig")
  end

  def test_handles_no_log_file
    assert_raise ApacheLookupError do
      ApacheLookup.new()
    end
  end

  def test_loads_log_file
    flunk "must make sure it is able to read in the file"
  end

  def test_bad_threadcount_value
    # "for when a user specifies a number of threads, but does so badly: 'foo'"
    al = ApacheLookup.new(%w(-t foo my_logs.log))
    assert_equal 5, al.options[:threads]
  end

  def test_resolves_domain_name
    # "use flexmock to capture rsolv's attempt and return 'example.com' or something."
    ip_address = "75.119.201.189"
    dns = "www.foo.com"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname).with(ip_address).once.and_return(dns)
    actual = al.lookup('75.119.201.189 - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406')
    expected = 'www.foo.com - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406'
    assert_equal actual, expected
  end

  def test_caches_domain_name
    flunk "use flexmock to make sure rsolv runs once, and then run again with same IP and make sure rsolv doesn't run the second time, but same result"
  end

  def test_cached_domain_name_ages_and_expires
    flunk "use flexmock to rsolv the IP, then make the cache for the given name look more than one day old, then make sure rsolv is used again for same IP"
  end

  def test_log_file_is_safely_written_to
    flunk "make sure the original log is preserved somehow, like appending a .orig to it, and that the original filename still exists with the new data."
  end

  def test_log_order_is_maintained
    flunk "make sure that the order (the date/time stamp) is still in ascending order, or maybe test to make sure it still matches what's in the original file"
  end

  def test_thread_management_is_working
    flunk "how the heck do we test this?"
  end
end