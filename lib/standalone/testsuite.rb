# !/usr/bin/env ruby
require 'byebug'
require 'ostruct'

=begin
    A QuickTest style test suite:
    generate short, random sequences and check if key characteristics of an
    attenuated sequence are met.

=end

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end

def characterise(gene)
    codons = GeneticCode.split_cdna_into_codons(gene.sequence)
    score = Statistics.sum(codons.collect.with_index do |codon, pos|
        unless GeneticCode.is_stopcodon(codon)
            Third_site_frequencies[codon].(pos)
        end
    end.compact)

    OpenStruct.new(
        seq: GeneticCode.translate(gene.sequence),
        GC: gene.sequence.count("GC"),
        CpG: gene.sequence.scan("CG").length,
        UpA: gene.sequence.scan("TA").length,
        score: score
    )
end

Logging.setup

100.times do |n|
    # randomly build sequence
    codons = GeneticCode.valid_codons.reject{|c| GeneticCode.is_stopcodon(c)}
    seq = "ATG"
    5.times do |sample|
        seq += codons.sample
    end
    seq += "TAA"

    gene = Gene.new
    gene.add_cds([seq], [], "test")
    before = characterise(gene)

    options = OpenStruct.new(
        greedy: true, strategy: "attenuate", select_by: "", stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
    )
    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)
    enhanced_gene = enhancer.select_best_gene
    after = characterise(enhanced_gene)

    # check key characteristics
    has_one_flagged= false
    flags = []
    unless before.seq == after.seq
        flags.push "seq failed"
        has_one_flagged = true
    end
    unless after.CpG >= before.CpG
        flags.push "CpG failed"
        has_one_flagged = true
    end
    unless after.UpA >= before.UpA || after.CpG > before.CpG
        # if UpA could not be increased, CpG should
        flags.push "UpA failed"
        has_one_flagged = true
    end
    unless after.GC <= before.GC || after.CpG > before.CpG
        # if GC could not be decreased, CpGs should be increased
        flags.push "GC/ at least CpG failed"
        has_one_flagged = true
    end
    unless after.score <= before.score || after.CpG > before.CpG || after.UpA > before.UpA
        # if score cound not be decreased, CpGs or UpAs should be increased
        flags.push "score/ at least CpG/UpA failed"
        has_one_flagged = true
    end
    if has_one_flagged
        puts "##{n} failed [#{flags.join("")}]: "
        puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene.sequence).join(" ")}\n"
    end
end