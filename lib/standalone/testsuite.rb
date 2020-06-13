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
        dnaseq: gene.sequence,
        protseq: GeneticCode.translate(gene.sequence),
        GC: gene.sequence.count("GC"),
        GC3: gene.gc3_content,
        T: gene.sequence.count("T"),
        CpG: gene.sequence.scan("CG").length,
        UpA: gene.sequence.scan("TA").length,
        score: score
    )
end

def tweak_gene_by(gene, strategy, select_by="")
    greedy = true
    options = OpenStruct.new(
        greedy: greedy, strategy: strategy, select_by: select_by, stay_in_subbox_for_6folds: false, score_eses_at_all_sites: false
    )
    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)
    enhancer.select_best_gene
end

def check_key_characteristics_for_attenuate_strategy(before, after)
    flags = []
    unless before.dnaseq != after.dnaseq
        flags.push "seq unchanged"
    end
    unless before.protseq == after.protseq
        flags.push "seq failed"
    end
    unless after.CpG >= before.CpG
        flags.push "CpG failed"
    end
    unless after.UpA >= before.UpA || after.CpG > before.CpG
        # if UpA could not be increased, CpG should
        flags.push "UpA failed"
    end
    unless after.GC <= before.GC || after.CpG > before.CpG
        # if GC could not be decreased, CpGs should be increased
        flags.push "GC/ at least CpG failed"
    end
    unless after.score <= before.score || after.CpG > before.CpG || after.UpA > before.UpA
        # if score cound not be decreased, CpGs or UpAs should be increased
        flags.push "score/ at least CpG/UpA failed"
    end
    flags
end

def check_key_characteristics_for_attenuate_maxT_strategy(before, after)
    flags = []
    unless before.dnaseq != after.dnaseq
        flags.push "seq unchanged"
    end
    unless before.protseq == after.protseq
        flags.push "seq failed"
    end
    unless after.T >= before.T
        flags.push "T failed"
    end
    unless after.GC <= before.GC
        flags.push "GC failed"
    end
    flags
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

    # strategy attenuate
    enhanced_gene = tweak_gene_by(gene, "attenuate")
    after = characterise(enhanced_gene)

    flags = check_key_characteristics_for_attenuate_strategy(before, after)
    if flags.any?
        puts "::attenuate:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene.sequence).join(" ")}\n"
    end

    # strategy attenuate-maxT
    enhanced_gene = tweak_gene_by(gene, "attenuate-maxT")
    after = characterise(enhanced_gene)

    flags = check_key_characteristics_for_attenuate_maxT_strategy(before, after)
    if flags.any?
        puts "::attenuate-maxT:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene.sequence).join(" ")}\n"
    end
end