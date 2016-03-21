# !/usr/bin/env ruby

# FIXME
require 'byebug'

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end

options = CommandlineOptions.new(ARGV)

# read in and parse data
gene = Gene.new(options.input, options.input_line)

# tweak exons
gene.tweak_exons

# remove introns (but the first)

# output sequence