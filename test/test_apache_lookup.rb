require 'test/unit'
require 'apache_lookup'
require 'rubygems'
require 'flexmock/test_unit'

class TestApacheLookup < Test::Unit::TestCase

  def setup
    File.delete('test_my_logs.log') if File.exists?('test_my_logs.log')
    File.delete('test_my_logs.log.orig') if File.exists?('test_my_logs.log.orig')
    # should make a local my_logs.log to work with so future runs of tests don't get clobbered by the last run
    
    # should delete the cache log if it exists to not clobber future tests.
  end

  def test_handles_no_log_file
    flunk "should fail to user if no log file is given."
  end

  def test_inappropriate_extra_arg
    flunk "for when a user provides something other than -t, a number, and a log file"
  end

  def test_bad_threadcount_value
    flunk "for when a user specifies a number of threads, but does so badly: '1s,4!'"
  end

  def test_resolves_domain_name
    flunk "use flexmock to capture rsolv's attempt and return 'example.com' or something."
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