#!/usr/bin/env ruby -w

require 'optparse'
require 'resolv'
require 'fileutils'
require 'time'
require 'thread'

class ApacheLookup
  VERSION = '0.2.1'
  CACHE_DECAY = 86400 # => one day, could be longer I suppose.
  CACHE_FILE = File.dirname(__FILE__) + "/lookup_cache.txt"
  attr_accessor :options, :log_data, :cache_data, :cache_mutex, :orig_file

  def initialize(args=[], options=nil)
    self.options = options || {:threads => 5}
    raise ApacheLookupError, "Threads value is invalid" unless self.options[:threads].class == Fixnum
    @log_data = Queue.new
    @cache_mutex = Mutex.new
    FileUtils.touch CACHE_FILE if !File.exists?(CACHE_FILE)
    load_cache
    load_log args.shift
  end

  def load_log file=""
    raise ApacheLookupError, "No log file supplied" if(file.nil? or file == "")
    @orig_file = file
    f = File.new(file)
    f.each {|line| @log_data << {:line => line.chomp, :num => f.lineno}}
  end

  def lookup log_line={}
    log_bits = log_line[:line].split(" - - ")
    dns = check_cache(log_bits[0].strip)
    if !dns
      begin
        timeout(0.5){
          dns = Resolv.getname(log_bits[0].strip)
          @cache_mutex.synchronize do
            @cache_data << "#{log_bits[0].strip}|#{dns}|#{Time.now}"
          end
        }
      rescue Timeout::Error, Resolv::ResolvError
        dns = log_bits[0]
      end
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

  private

  def load_cache
    @cache_data = File.readlines(CACHE_FILE)
  end

  def check_cache(ip)
    @cache_mutex.synchronize do
      found_and_current = nil
      @cache_data.each do |cd|
        bits = cd.split("|")
        if bits[0] == ip
          if ((Time.now - Time.parse(bits[2])) < CACHE_DECAY)
            found_and_current = bits[1]
          else
            @cache_data.reject!{|line| line[0] == bits[0]}
          end
        end
      end
      found_and_current
    end
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