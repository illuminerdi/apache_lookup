#!/usr/bin/env ruby -w

require 'optparse'
require 'resolv'

class ApacheLookup
  VERSION = '0.0.1'
  
  attr_accessor :options, :log_data
  
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
  end
  
  def lookup log_line=""
    log_bits = log_line.split('-')
    dns = Resolv.getname(log_bits[0].strip)
    log_bits[0] = "#{dns} "
    log_bits.join('-')
  end
end

class ApacheLookupError < Exception; end

ApacheLookup.new(ARGV) if __FILE__ == $0