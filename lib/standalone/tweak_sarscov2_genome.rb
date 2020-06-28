# !/usr/bin/env ruby
require 'byebug' # FIXME - remove if byebug gem is not installed!
require 'ostruct'
require 'optparse'

=begin
    Tweak coding regions individually and output generated variants.

    Gene locations are extracted from location tags in "coding sequences" file.
    NOTE:
        NCBI feature records are 1-based and thus converted to 0-based ruby counting.

    Input file: whole genome sequence

=end

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end

class OptParser
    def self.parse(args)

        options = Hash.new

        # mandatory parameters
        options[:input] = nil
        options[:output] = nil

        opt_parser = OptionParser.new do |opts|
            opts.banner = "Attenuate SARS-CoV-2 genes."
            opts.separator ""
            opts.separator "Copyright (c) 2020, by University of Bath"
            opts.separator "Contributors: Stefanie Mühlhausen"
            opts.separator "Affiliation: Laurence D Hurst"
            opts.separator "Contact: l.d.hurst@bath.ac.uk"
            opts.separator "This program comes with ABSOLUTELY NO WARRANTY"

            opts.separator ""
            opts.separator "Usage: ruby #{File.basename($PROGRAM_NAME)} -i input -o output"

            opts.on("-i", "--input FILE",
                "Path to input file, in FASTA format.") do |path|
                FileHelper.file_exist_or_die(path)
                options[:input] = path
            end
            opts.on("-o", "--output FILE",
                "Path to output file, in FASTA format.") do |path|
                options[:output] = path
            end
            opts.separator ""
            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end

        end # optionparser

        ## main part of function ##
        if args.empty? then
            # display help and exit if program is called without any argument
            puts opt_parser.help
            exit
        end

        opt_parser.parse(args)

        # ensure mandatory arguments are present
        abort "Missing mandatory argument: --input" unless options[:input]
        abort "Missing mandatory argument: --output" unless options[:output]
        return options
    end # parse()
end

def select_variants_by_GC(gene, enhancer, cpg_enrichment)
    # extract variant seqs from fasta
    variants = []
    enhancer.fasta_formatted_gene_variants.each do |fasta|
        lines = fasta.split("\n")
        variants.push lines[1..-1].join("")
    end
    variants = variants.uniq

    # calculate target G+C content
    original_GC = gene.sequence.count("GC") / gene.sequence.size.to_f
    max_GC =
        if cpg_enrichment < 1
            original_GC + original_GC * (1 - cpg_enrichment)
        else
            original_GC
        end

    # select variants below maximum tolerable GC
    variants.select do |variant|
        variant.count("GC") / gene.sequence.size.to_f <= max_GC
    end
end

def set_attenuate_options(cpg_enrichment)
    # standard sequence optimiser options
    OpenStruct.new(
        strategy: "attenuate", stay_in_subbox_for_6folds: false,
        CpG_enrichment: cpg_enrichment
    )
end

Logging.setup
options = OptParser.parse(ARGV)

# read in file
header, seq = "", ""
IO.foreach(optins[:input]) do |line|
    line = line.chomp
    if line.start_with?(">")
        raise EnhancerError, "Input expected to be single fasta" if header.start_with?(">")
        header = line
    else
        seq += line
    end
end

# define gene locations
# NOTE - overlapping genes are ORF1a/b and ORF7a/b
# positions are according to manuscript
# in addition, advoid mutating region forming pseudonot between 13476 and 13542
pos = {
    "orf1a" => [265, 13464],
    "orf1b" => [13542, 21551],
    "s" => [21562, 25383],
    "orf3a" => [25392, 26219],
    "e" => [26244, 26471],
    "m" => [26522, 27190],
    "orf6" => [27201, 27386],
    "orf7a" => [27393, 27752],
    "orf7b" => [27761, 27886],
    "orf8" => [27893, 28258],
    "n" => [28273, 29532],
    "orf10" => [29557, 29673]
}
cpg_enrichment = {
    "orf1a" => 0.3423539707737651,
    "orf1b" => 0.4127108603224809,
    "s" => 0.21812663685889996,
    "orf3a" => 0.5293749739398741,
    "m" => 0.6602951581807313,
    "orf6" => 0.27663521509675365,
    "orf7a" => 0.5331021328246923,
    "orf7b" => 0.32599910193084863,
    "orf8" => 0.684706603966469,
    "n" => 0.5575853852263701,
    "e" => 1.3328298720369205,
    "orf10" => 1.4788047705470573,
}


pos.each do |key, data|
    start, stop = data
    mod = seq[start..stop].size % 3
    if mod != 0
        raise "should not happen!"
    end
    puts "#{key}: [#{Counting.ruby_to_human(start)} - #{Counting.ruby_to_human(stop)}]"
    orf = seq[start..stop]

    $logger.info("Tweaking gene #{key.upcase} located at [#{start}..#{stop}]")
    gene = Gene.new
    gene.add_cds([orf.upcase], [], key.upcase)
    gene.log_statistics

    options = set_attenuate_options(cpg_enrichment[key])
    enhancer = GeneEnhancer.new(options)

    enhancer.generate_synonymous_genes(gene)
    variants = select_variants_by_GC(gene, enhancer, options.CpG_enrichment)

    puts variants.size
    fh = File.open(options[:output] + "_#{key}.csv", "w")
    fh.puts key
    fh.puts variants.join("\n")
    fh.close
end
