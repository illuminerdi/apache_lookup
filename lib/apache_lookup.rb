#!/usr/bin/env ruby -w

require 'optparse'
require 'resolv'
require 'fileutils'
require 'time'
require 'thread'

class ApacheLookup
  VERSION = '0.0.1'
  CACHE_DECAY = 86400

  attr_accessor :options, :log_data, :cache_file, :orig_file

  CACHE_FILE = File.dirname(__FILE__) + "/lookup_cache.txt"

  def initialize(args=[])
    self.options = {:threads => 5}

    OptionParser.new do |opts|
      opts.banner = "Usage: apache_lookup [-t] NUM_THREADS log_file.log"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-t NUM_THREADS", "Maximum number of threads to use for parsing") do |t|
        self.options[:threads] = t.to_i if t.to_i > 0
      end
      opts.on("-h", "This information") do |h|
        puts opts
        exit 0
      end
    end.parse!(args)
    load_log args.shift
  end

  def load_log file=""
    raise ApacheLookupError, "No log file supplied" if(file.nil? or file == "")
    @orig_file = file
    @log_data = File.readlines(file).map {|line| line.chomp}
  end

  def lookup log_line=""
    log_bits = log_line.split(" - - ")
    dns = get_cache(log_bits[0].strip)
    if !dns
      begin
        dns = Resolv.getname(log_bits[0].strip)
      rescue Resolv::ResolvError
        dns = log_bits[0]
      end
      FileUtils.touch CACHE_FILE if !File.exists?(CACHE_FILE)
      cf = File.open(CACHE_FILE, "r+")
      to_write = "#{log_bits[0].strip}|#{dns}|#{Time.now}"
      cf.puts(to_write)
      cf.close
    end
    log_bits[0] = "#{dns}"
    log_bits.join(" - - ")
  end

  def resolve
    queue = Queue.new
    resolved = []
    while !@log_data.empty?
      while queue.size <= @options[:threads]
        Thread.new do
          queue << lookup(@log_data.shift)
        end
      end
      consumer = Thread.new do
        queue.size.times do |i|
          resolved << queue.pop
        end
      end
      consumer.join
    end
    @log_data = resolved
    #resolved = []
    #threads = []
    #@log_data.each{|line| 
    #  threads << Thread.new{resolved << lookup(line)}
    #}
    #threads.each {|t| t.join}
    #@log_data = resolved
  end

  def write
    FileUtils.cp(@orig_file, "#{@orig_file}.orig")
    File.open(@orig_file, "w") {|file|
      @log_data.each {|line|
        file.puts(line)
      }
    }
  end

  def self.run args=[]
    al = ApacheLookup.new(args)
    al.resolve
    al.write
  end

  private

  def get_cache(ip)
    found_and_current = false
    return found_and_current if !File.exists?(CACHE_FILE)
    File.open(CACHE_FILE, "r") do |file|
      file.each do |line|
        bits = line.split("|")
        if bits[0] == ip and ((Time.now - Time.parse(bits[2])) < CACHE_DECAY)
          found_and_current = bits[1]
        end
      end
    end
    found_and_current
  end
end

class ApacheLookupError < Exception; end