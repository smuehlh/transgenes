# !/usr/bin/env ruby
require 'byebug'
require 'ostruct'

=begin
    Tweak coding regions individually and paste tweaked sequence into original location.

    Gene locations are extracted from location tags in "coding sequences" file.
    NOTE:
        NCBI feature records are 1-based and thus converted to 0-based ruby counting.

    Input file: whole genome sequence

=end

input = "/Users/sm2547/Documents/sars-cov2/data/SARS-CoV-2_refseq_NC_045512_complete_genome.fasta"
output = "/Users/sm2547/Documents/sars-cov2/data/tweaked_SARS-CoV-2_refseq_NC_045512_complete_genome.fasta"

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end
Logging.setup

# standard sequence optimiser options
options = OpenStruct.new(
    greedy: true, strategy: "attenuate", select_by: "", stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
)

# read in file
header, seq = "", ""
IO.foreach(input) do |line|
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
pos = {
    "orf1a" => [265, 13482],
    "orf1ab" => [[265, 13467], [13467, 21554]], # -1 ribosomal slippage
    "s" => [21562, 25383],
    "orf3a" => [25392, 26219],
    "e" => [26244, 26471],
    "m" => [26522, 27190],
    "orf6" => [27201, 27386],
    "orf7a" => [27393, 27758],
    "orf7b" => [27755, 27886],
    "orf8" => [27893, 28258],
    "n" => [28273, 29532],
    "orf10" => [29557, 29673]
}

tweaked_seq = seq
pos.each do |key, data|
    start, stop = data
    if key == "orf1a"
        # overlaps with orf1ab => end 1 nt before ribosomal slippage in orf1ab
        stop = pos["orf1ab"][0][1] - 1
    elsif key == "orf1ab"
        # focus on sub-sequence not part of ORF1a, i.e. 2nd set of coordinates
        start = pos["orf1a"][1] + 1
        stop = data[1][1]
    elsif  key == "orf7a"
        # overlaps with orf7b => end 1 nt before orf7b
        stop = pos["orf7b"][0] - 1
    end
    mod = seq[start..stop].size % 3
    if mod != 0
        if key == "orf1a" || key == "orf7a"
            # trim ORF at end of sequence (since stop pos was messed with)
            stop -= mod
        elsif key == "orf1ab"
            # trim ORF at beginning of sequence (start pos was messed with)
            start += mod
        else
            raise "should not happen!"
        end
    end
    orf = seq[start..stop]

    $logger.info("Tweaking gene #{key.upcase} located at [#{start}..#{stop}]")
    gene = Gene.new
    gene.add_cds([orf.upcase], [], key.upcase)
    gene.log_statistics

    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)
    enhanced_gene = enhancer.select_best_gene

    tweaked_seq[start..stop] = enhanced_gene.sequence
end

FileHelper.write_to_file(output, "#{header}\n#{tweaked_seq}")
