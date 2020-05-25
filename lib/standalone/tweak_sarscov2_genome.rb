# !/usr/bin/env ruby
require 'byebug'
require 'ostruct'

=begin
    Tweak coding regions individually and paste tweaked sequence into original location.

    Calculate key characteristics of tweaked sequence.

    Gene locations are extracted from location tags in "coding sequences" file.
    NOTE:
        NCBI feature records are 1-based and thus converted to 0-based ruby counting.

    Input file: whole genome sequence

=end

input = "/Users/sm2547/Documents/sars-cov2/data/GISAID_EPI_ISL_402124_complete_genome.fasta"
output = "/Users/sm2547/Documents/sars-cov2/data/tweaked_GISAID_EPI_ISL_402124_complete_genome.fasta"
csv = "/Users/sm2547/Documents/sars-cov2/data/tweaked_GISAID_EPI_ISL_402124_complete_genome_stats.csv"

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end
Logging.setup

# standard sequence optimiser options
attenuate_options = OpenStruct.new(
    greedy: true, strategy: "attenuate-wo-UpA", select_by: "", stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
)
attenuate_maxT_options = OpenStruct.new(
    greedy: true, strategy: "attenuate-maxT", select_by: "", stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
)
attenuate_keep_GC3_options = OpenStruct.new(
    greedy: false, strategy: "attenuate-keep-GC3", select_by: "stabilise", stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
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
# positions are according to manuscript
pos = {
    "orf1a" => [265, 13464],
    "orf1b" => [13470, 21551],
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
gene_desc = {} # characteristics of tweaked sequence

tweaked_seq = seq
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

    options =
        if ["orf1a", "orf1b", "orf6", "orf7b", "s"].include?(key)
            attenuate_options
        elsif ["e", "orf10"].include?(key)
            attenuate_maxT_options
        else
            attenuate_keep_GC3_options
        end
    enhancer = GeneEnhancer.new(options)

    enhancer.generate_synonymous_genes(gene)
    begin
        enhanced_gene = enhancer.select_best_gene
    rescue
        # NOTE - this requires fail-saveness in method select_best_gene to be commented
        # failed if all generated variants have higher GC3 than original seq
        puts "Cannot tweak: #{key}; GC3 target cannot be met"
        next
    end

    tweaked_seq[start..stop] = enhanced_gene.sequence

    # collect sequence characteristics
    gene_desc[key] = {
        dnaseq: enhanced_gene.sequence,
        GC3: enhanced_gene.gc3_content,
        changed_sites: enhanced_gene.log_changed_sites[0],
        A: enhanced_gene.sequence.count("A"),
        T: enhanced_gene.sequence.count("T"),
        C: enhanced_gene.sequence.count("C"),
        G: enhanced_gene.sequence.count("G"),
        GC: enhanced_gene.sequence.count("GC"),
        AT: enhanced_gene.sequence.count("AT"),
        CpG: enhanced_gene.sequence.scan("CG").length,
        UpA: enhanced_gene.sequence.scan("TA").length,
    }

end

FileHelper.write_to_file(output, "#{header}\n#{tweaked_seq}")

data = "Gene,Start-Stop,A,T,C,G,GC,AT,CpG,UpA,GC3,changed sites,sites,seq length,seq\n"
gene_desc.each do |key, desc|
    data += key.upcase + ","
    data += "#{Counting.ruby_to_human(pos[key][0])} - #{Counting.ruby_to_human(pos[key][1])},"
    data += [desc[:A], desc[:T], desc[:C], desc[:G]].join(",") + ","
    data += [desc[:GC], desc[:AT]].join(",") + ","
    data += [desc[:CpG], desc[:UpA], desc[:GC3]].join(",") + ","
    data += desc[:changed_sites].to_s + ","
    data += (desc[:dnaseq].size/3).to_s + ","
    data += desc[:dnaseq].size.to_s + ","
    data += desc[:dnaseq] + "\n"
end
FileHelper.write_to_file(csv, data)
