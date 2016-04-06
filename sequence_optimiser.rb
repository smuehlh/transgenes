# !/usr/bin/env ruby

# FIXME
require 'byebug'

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end
ErrorHandling.is_commandline_tool = true

options = CommandlineOptions.new(ARGV)

# read in and parse data
gene = Gene.new(options.input, options.input_line)

# determine what to do by command line parameters!
# tweak exons
# humanize codons
# remove introns ...
gene.tweak_sequence

# output sequence
FileHelper.write_to_file(options.output, gene.formatting_to_fasta)