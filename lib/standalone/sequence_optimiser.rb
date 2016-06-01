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
gene = Gene.new
gene.add_cds(*ToGene.init_and_parse("CDS", options.input, options.input_line))
if options.utr5prime
    gene.add_five_prime_utr(
        *ToGene.init_and_parse("5'UTR", options.utr5prime, options.utr5prime_line)
    )
end
if options.utr3prime
    gene.add_three_prime_utr(
        *ToGene.init_and_parse("3'UTR", options.utr3prime, options.utr3prime_line)
    )
end

# remove unwanted introns
gene.remove_introns(options.remove_first_intron)
puts gene.print_statistics

# determine what to do by command line parameters!
# tweak exons
# humanize codons
gene.tweak_sequence(options)

# output sequence
FileHelper.write_to_file(options.output, gene.formatting_to_fasta)