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

def calculate_key_values(seq)
    len = seq.size.to_f
    propC = seq.upcase.count("C")/len
    propG = seq.upcase.count("G")/len
    propA = seq.upcase.count("A")/len
    propU = seq.upcase.count("T")/len
    propCG = seq.upcase.scan("CG").size/(len-1)
    propUA = seq.upcase.scan("TA").size/(len-1)
    cpge = propCG/(propC * propG)
    upae = propUA/(propU * propA)
    return [cpge, upae, propU]
end

def set_attenuate_options(data)
    OpenStruct.new(
        strategy: "attenuate",
        stay_in_subbox_for_6folds: false,
        CpG_enrichment: data.CpGe,
        TpA_enrichment: data.UpAe,
    )
end

Logging.setup
options = OptParser.parse(ARGV)

# read in file
header, seq = "", ""
IO.foreach(options[:input]) do |line|
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
# NOTE - CpG enrichment and UpA enrichment are calculated according to manuscript
genes = {
    "ORF1A" => OpenStruct.new(start: 265, stop: 13464, CpGe: 0.3423539707737651, UpAe: 0.8496535598611519, propU: 0.3239393939393939),
    "ORF1B" =>OpenStruct.new(start: 13542, stop: 21551, CpGe: 0.4017345703798582, UpAe: 0.8852687578224665, propU: 0.3240948813982522),
    "S" => OpenStruct.new(start: 21562, stop: 25383, CpGe: 0.21812663685889996, UpAe: 0.7111936844935985, propU: 0.3325484039769754),
    "ORF3A" => OpenStruct.new(start: 25392, stop: 26219, CpGe: 0.5293749739398741, UpAe: 0.7208706166868201, propU: 0.3333333333333333),
    "E" => OpenStruct.new(start: 26244, stop: 26471, CpGe: 1.3328298720369205, UpAe: 1.066790707855638, propU: 0.40350877192982454),
    "M" => OpenStruct.new(start: 26522, stop: 27190, CpGe: 0.6602951581807313, UpAe: 0.846170520338123, propU: 0.3183856502242152),
    "ORF6" => OpenStruct.new(start: 27201, stop: 27386, CpGe: 0.27663521509675365, UpAe: 0.8333574215927158, propU: 0.3548387096774194),
    "ORF7A" => OpenStruct.new(start: 27393, stop: 27752, CpGe: 0.5421625184739847, UpAe: 0.6464844347852703, propU: 0.325),
    "ORF7B" => OpenStruct.new(start: 27761, stop: 27886, CpGe: 0.33075000000000004, UpAe: 0.7683484573502724, propU: 0.4523809523809524),
    "ORF8" => OpenStruct.new(start: 27893, stop: 28258, CpGe: 0.684706603966469, UpAe: 0.894864076471029, propU: 0.366120218579235),
    "N" => OpenStruct.new(start: 28273, stop: 29532, CpGe: 0.5575853852263701, UpAe: 0.5115380580574581, propU: 0.21031746031746032),
    "ORF10" => OpenStruct.new(start: 29557, stop: 29673, CpGe: 1.4788047705470573, UpAe: 1.2844475721323012, propU: 0.358974358974359)
}

fh = File.open(options[:output], "w")
genes.each do |gene_name, data|
    orf = seq[data.start..data.stop]
    raise "sequence not a multiple of" if orf.size % 3 != 0

    puts "#{gene_name}: [#{Counting.ruby_to_human(data.start)} - #{Counting.ruby_to_human(data.stop)}]"
    $logger.info("Tweaking gene #{gene_name} located at [#{data.start}..#{data.stop}]")

    gene = Gene.new
    gene.add_cds([orf.upcase], [], gene_name)
    gene.log_statistics

    options = set_attenuate_options(data)
    enhancer = GeneEnhancer.new(options)

    enhancer.generate_synonymous_genes(gene)
    variants = select_variants_by_GC(gene, enhancer, data.CpGe)

    puts variants.size
    variants.each_with_index do |variant, ind|
        v_CpGe, v_UpAe, v_propU = calculate_key_values(variant)
        header = "#{gene_name}_variant#{Counting.ruby_to_human(ind)}"
        header += " CpGe:#{v_CpGe.round(2)}|UpAe:#{v_UpAe.round(2)}|Prop U:#{v_propU.round(2)}"
        # flag variants with key values raised above wild-type
        if data.CpGe <= 1
            if v_CpGe > data.CpGe && v_UpAe > data.UpAe && v_propU > data.propU
                header += " above wild-type"
            end
        else
            if v_propU > data.propU && v_CpGe < data.CpGe
                header += " above wild-type"
            end
        end
        fh.puts GeneToFasta.new(header, variant).fasta
    end
end
fh.close
