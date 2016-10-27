# !/usr/bin/env ruby

require 'byebug' # FIXME. Important: FIXME and require must be in same line in order to remove both from automatically generated zip-archive.

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end
# NOTE: setup logging first thing. do all the (possibly wrong-going) stuff afterwards
ErrorHandling.is_commandline_tool = true
$logger = MultiLogger.new(*Logging.default_setup_commandline_tool)

options = CommandlineOptions.new(ARGV)
Logging.switch_to_verbose_setup_commandline_tool if options.verbose

# read in and parse data
gene = Gene.new
gene.add_cds(*ToGene.init_and_parse("CDS", options.input, options.input_line))
gene.add_five_prime_utr(
    *ToGene.init_and_parse("5'UTR", options.utr5prime, options.utr5prime_line)
) if options.utr5prime
gene.add_three_prime_utr(
    *ToGene.init_and_parse("3'UTR", options.utr3prime, options.utr3prime_line)
) if options.utr3prime
gene.add_ese_list(EseToGene.init_and_parse(options.ese)) if options.ese

# remove unwanted introns
gene.remove_introns(options.remove_first_intron)
gene.log_statistics

# tweak sequence
gene.tweak_sequence(options.strategy, options.stay_in_subbox_for_6folds)
gene.log_tweak_statistics

# output sequence
GeneToFasta.write(options.output, gene)