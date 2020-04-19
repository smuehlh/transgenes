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
    "orf1ab" => [265, 21554],
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
    next if key == "orf1ab" # 'merged' ORF1a and ORF1b
    start, stop = data
    if  key == "orf7a"
        # overlaps with orf7b => end 1 nt before orf7b
        stop = pos["orf7b"][0] - 1
    end
    orf = seq[start..stop]
    $logger.info("Tweaking gene #{key.upcase} located at [#{start}..#{stop}]")

    gene = Gene.new
    gene.add_cds([orf.upcase], [], key.upcase)

    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)
    enhanced_gene = enhancer.select_best_gene

    tweaked_seq[start..stop] = enhanced_gene.sequence
end

FileHelper.write_to_file(output, "#{header}\n#{tweaked_seq}")

# TODO - what to do about ORF1b?
# length protein transcript: 2595 -> should start at pos 21554-2595*3+1
# => doesn't start with ATG ...
# slippage imideately upstream ORF1A stop => no ATG there
# nearest ATGs: 13432, 13448, 13525, 15555

# => look into: https://www.ncbi.nlm.nih.gov/nuccore/NC_045512
# for gene coordinates!

# TODO gene.log_statistics to log stats of full sequence before/ after tweaking.
