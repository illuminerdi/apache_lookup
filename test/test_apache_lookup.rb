require 'test/unit'
require 'apache_lookup'
require 'rubygems'
require 'flexmock/test_unit'

class TestApacheLookup < Test::Unit::TestCase

  def setup
    @dir = "#{FileUtils.pwd}/test"
    @cache = File.dirname(__FILE__) + "/../lib/lookup_cache.txt"
    @log_line = '75.119.201.189 - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406'
    @mock_log_line = 'www.foo.com - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406'
    # should make a local my_logs.log to work with so future runs of tests don't get clobbered by the last run
    FileUtils.cp("#{@dir}/my_logs.log", "#{@dir}/test_my_logs.log")

    # should delete the cache log if it exists to not clobber future tests.
    File.delete(@cache) if File.exists?(@cache)
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
    # "must make sure it is able to read in the file"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    assert_equal 12, al.log_data.size
  end

  def test_handles_bad_threadcount_value
    # "for when a user specifies a number of threads, but does so badly: 'foo'"
    al = ApacheLookup.new(["-t", "foo", "#{@dir}/test_my_logs.log"])
    assert_equal 5, al.options[:threads]
  end

  def test_resolves_domain_name
    # "use flexmock to capture rsolv's attempt and return 'example.com' or something."
    ip_address = "75.119.201.189"
    dns = "www.foo.com"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname).with(ip_address).once.and_return(dns)
    assert_equal @mock_log_line, al.lookup(@log_line)
  end

  def test_caches_domain_name
    # "use flexmock to make sure resolv runs once, and then run again with same IP and make sure rsolv doesn't run the second time, but same result"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname => "www.foo.com").at_most.once
    first = al.lookup(@log_line)
    alter_cache(ApacheLookup::CACHE_FILE, :dns, "75.119.201.189")
    second = al.lookup(@log_line)
    expected = 'www.bar.com - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406'
    assert_equal expected, second
  end

  def test_cached_domain_name_ages_and_expires
    # "use flexmock to resolv the IP, then make the cache for the given name look more than one day old, then make sure rsolv is used again for same IP"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname => "www.foo.com").at_most.times(2).at_least.times(2)
    first = al.lookup(@log_line)
    alter_cache(@cache, :time, "75.119.201.189")
    assert_equal @mock_log_line, al.lookup(@log_line)
  end

  def test_log_file_is_safely_written_to
    #flunk "make sure the original log is preserved somehow, like appending a .orig to it, and that the original filename still exists with the new data."
    # this looks like it would be equivalent to a ApacheLookup#run call...
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname => "www.foo.com")
    al.resolve
    al.write
    assert File.exists?("#{@dir}/test_my_logs.log.orig")
    assert !FileUtils.identical?("#{@dir}/test_my_logs.log", "#{@dir}/test_my_logs.log.orig")
    assert FileUtils.identical?("#{@dir}/test_my_logs.log.orig", "#{@dir}/my_logs.log")
  end

  def test_log_order_is_maintained
    #flunk "make sure that the order (the date/time stamp) is still in ascending order, or maybe test to make sure it still matches what's in the original file"
    al = ApacheLookup.new(["#{@dir}/test_my_logs.log"])
    flexmock(Resolv).should_receive(:getname => "www.foo.com")
    al.resolve
    al.write
    orig = File.readlines("#{@dir}/test_my_logs.log.orig").map{|line| line.chomp}
    resolved = File.readlines("#{@dir}/test_my_logs.log").map{|line| line.chomp}
    (0...orig.size).each do |i|
      actual = orig[i].split(" - - ")
      if resolved[i].nil?
        raise resolved.size.inspect
      end
      expected = resolved[i].split(" - - ")
      assert_equal orig[i].split(" - - ")[1], resolved[i].split(" - - ")[1]
    end
  end

  def alter_cache(cache_file, value, lookup)
    cf = File.readlines(cache_file)
    cf = cf.map {|l|
      if l =~ /#{lookup}/
        line_bits = l.split("|")
        line_bits[1] = "www.bar.com"
        if value == :time
          line_bits[2] = "#{Time.now-90_000}"
        end
        line_bits.join("|")
      else 
        l
      end
    }
    File.open(cache_file, "w") do |file|
      cf.each do |line|
        file.write(line)
      end
    end
  end
end