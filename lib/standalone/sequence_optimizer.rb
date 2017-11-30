# !/usr/bin/env ruby

require 'byebug' # FIXME. Important: FIXME and require must be in same line in order to remove both from automatically generated zip-archive.

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end
# NOTE: setup logging first thing. do all the (possibly wrong-going) stuff afterwards
Logging.setup
options = CommandlineOptions.new(ARGV)
Logging.switch_to_verbose if options.verbose

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
if options.ese
    gene.add_ese_list(EseToGene.init_and_parse(options.ese))
end
if options.restriction_enzymes_to_keep
    gene.add_restriction_sites_to_keep_intact(
        RestrictionEnzymeToGene.init_and_parse(options.restriction_enzymes_to_keep)
    )
end
if options.restriction_enzymes_to_avoid
    gene.add_restriction_enzymes_to_avoid(
        RestrictionEnzymeToGene.init_and_parse(options.restriction_enzymes_to_avoid)
    )
end

# remove unwanted introns
gene.remove_introns(options.remove_first_intron)
gene.log_statistics

if options.wildtype
    $logger.info("Output wildtype and exit programm")
    GeneToFasta.write(options.output, gene)
    exit
end

# tweak sequence
enhancer = GeneEnhancer.new(
    options.strategy, options.ese_strategy, options.select_by,
    options.stay_in_subbox_for_6folds
)
enhancer.generate_synonymous_genes(gene)
enhanced_gene = enhancer.select_best_gene

# output sequence
GeneToFasta.write(options.output, enhanced_gene)