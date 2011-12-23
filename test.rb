#!/usr/bin/env ruby

require 'rubygems'
require 'rsruby'
require 'ruby_lib/exceptor'

r = RSRuby.instance

root_path = Dir.pwd
script_path = File.join(root_path, 'r_scripts')
main_script = File.join(script_path, 'fcs3_analysis.r')
replicate_path = File.join(root_path, 'example_replicate')
out_path = File.join(root_path, 'output')
dump_file = File.join(out_path, 'out.dump')

# channels for the different wells
channels = {
  'A01' => 'RED',
  'A03' => 'GRN',
  'T07' => 'RED'
}

min_cells = 100 # if there are fewer cells than this, ignore the well

begin

  r.setwd(script_path)
  r.source(main_script)
  
  # fluo = 'RED'
  fluo = 'GRN'
  init_gate = 'ellipse'
  #init_gate = 'rectangle'

  # Build array of fcs files to be analyzed
  fcs_file_paths = []
  dir = Dir.new(replicate_path)
  dir.each do |fcs_file|
    next if (fcs_file == '.') || (fcs_file == '..')
    fcs_file_path = File.join(replicate_path, fcs_file)
    next if File.directory?(fcs_file_path)
    next if !fcs_file.match(/.+\.fcs3?$/i)
    fcs_file_paths << fcs_file_path
  end

  # Run the analysis
  data_set = Exceptor.call_r_func(r, r.batch, out_path, fcs_file_paths, :fluo_channel => 'GRN', :well_channels => channels, :init_gate => init_gate, :verbose => true, :min_cells => min_cells)

  puts "================================================="
  puts "                    Results                      "
  puts "================================================="
  puts " "

  data_set.each_pair do |file, data|
    puts "Analysis of file #{file}:"

    if data['well_name']
      puts "  Well: #{data['well_name']}"
    else
      puts "  Well: unknown"
    end
    if data['fluo_channel']
      puts "  Fluorescence channel: #{data['fluo_channel']}"
    else
      puts "  Fluorescence channel: unknown"
    end

    if data['error']
      puts "  Encountered an error: #{data['error']}"
    else
      puts "  Completed successfully"
      # Dump file for debugging
      f = File.new(dump_file, 'w+')
      f.puts(data_set.inspect)
      f.close
    end
    puts " "
  end


  puts "Analysis completed."
  puts "Cleaned fcs files and plots in: #{out_path}"
  puts "Output data dumped to: #{dump_file}"

rescue Exception => e
  if(e.message[:r_msg])
    puts "Error message from R: "
    puts " "
    puts e.message[:r_msg]
    puts " "
    puts "R backtrace:"
    puts " "
    puts e.message[:r_backtrace].join("\n")
    puts " "
  else
    puts "Error message from Ruby: "
    puts " "
    puts e.message
    puts " "
  end
  puts "Ruby backtrace: "
  puts " "
  puts e.backtrace.join("\n")
end
