#!/usr/bin/env ruby -w

require 'optparse'
require 'resolv'
require 'fileutils'
require 'time'
require 'thread'

class ApacheLookup
  VERSION = '0.0.1'
  CACHE_DECAY = 86400

  attr_accessor :options, :log_data, :cache_data, :orig_file

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
    @log_data = Queue.new
    FileUtils.touch CACHE_FILE if !File.exists?(CACHE_FILE)
    load_cache
    load_log args.shift
  end

  def load_log file=""
    raise ApacheLookupError, "No log file supplied" if(file.nil? or file == "")
    @orig_file = file
    f = File.new(file)
    f.each {|line| @log_data << {:line => line.chomp, :num => f.lineno-1}}
  end

  def lookup log_line={}
    log_bits = log_line[:line].split(" - - ")
    dns = check_cache(log_bits[0].strip)
    if !dns
      begin
        timeout(2){
          dns = Resolv.getname(log_bits[0].strip)
        }
      rescue Timeout::Error, Resolv::ResolvError
        dns = log_bits[0]
      end
      @cache_data << "#{log_bits[0].strip}|#{dns}|#{Time.now}"
    end
    log_bits[0] = "#{dns}"
    {:num => log_line[:num], :line => log_bits.join(" - - ")}
  end

  def resolve
    consumers = []
    resolved = []
    @options[:threads].times do |thread|
      consumers << Thread.new do
        until(@log_data.empty?)
          resolved << lookup(@log_data.shift)
        end
      end
    end
    consumers.each{|c| c.join}
    @log_data = resolved
  end

  def write(reload=true)
    FileUtils.cp(@orig_file, "#{@orig_file}.orig")
    @log_data.sort!{|a,b| a[:num].to_i <=> b[:num].to_i}
    File.open(@orig_file, "w") {|file|
      @log_data.each {|data|
        file.puts(data[:line])
      }
    }
    write_cache
    load_cache if reload
  end

  def self.run args=[]
    al = ApacheLookup.new(args)
    al.resolve
    al.write(false)
  end

  private
  
  def load_cache
    @cache_data = File.readlines(CACHE_FILE)
  end

  def check_cache(ip)
    found_and_current = false
    @cache_data.each do |cd|
      bits = cd.split("|")
      if bits[0] == ip and ((Time.now - Time.parse(bits[2])) < CACHE_DECAY)
        found_and_current = bits[1]
      end
    end
    found_and_current
  end
  
  def write_cache
    File.open(CACHE_FILE, "w") do |f|
      @cache_data.each do |cd|
        f.puts(cd)
      end
    end
  end
end
class ApacheLookupError < Exception; end