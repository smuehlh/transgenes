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

def characterise(sequence)
    OpenStruct.new(
        dnaseq: sequence,
        protseq: GeneticCode.translate(sequence),
        GC: sequence.count("GC"),
        T: sequence.count("T"),
        CpG: sequence.scan("CG").length,
        UpA: sequence.scan("TA").length,
    )
end

def characterise_variants(seqs)
    OpenStruct.new(
        dnaseq: seqs.first,
        protseq: GeneticCode.translate(seqs.first),
        GC: Statistics.mean(seqs.collect{|s| s.count("GC")}),
        T: Statistics.mean(seqs.collect{|s| s.count("T")}),
        CpG: Statistics.mean(seqs.collect{|s| s.scan("CG").size}),
        UpA: Statistics.mean(seqs.collect{|s| s.scan("TA").size}),
    )
end

def tweak_gene_by(gene, strategy, cpg_enrichment)
    options = OpenStruct.new(
        strategy: strategy, CpG_enrichment: cpg_enrichment, stay_in_subbox_for_6folds: false
    )
    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)

    variants = []
    enhancer.fasta_formatted_gene_variants.each do |fasta|
        lines = fasta.split("\n")
        variants.push lines[1..-1].join("")
    end
    # calculate target G+C content
    original_GC = gene.sequence.count("GC") / gene.sequence.size.to_f
    max_GC = original_GC + original_GC * (1 - cpg_enrichment)

    # select variants below maximum tolerable GC
    variants.select do
        |variant| variant.count("GC") / gene.sequence.size.to_f <= max_GC
    end
end

def check_key_characteristics_for_attenuate_strategy_low_CpGe(before, after)
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
    unless after.T <= before.T
        flags.push "T failed"
    end
    unless after.GC <= before.GC * 2
        flags.push "selection by GC failed"
    end
    flags
end

def check_key_characteristics_for_attenuate_strategy_mean_CpGe(before, after)
    flags = []
    unless before.dnaseq != after.dnaseq
        flags.push "seq unchanged"
    end
    unless before.protseq == after.protseq
        flags.push "seq failed"
    end
    # unless after.CpG = before.CpG
    #     flags.push "CpG failed"
    # end
    # unless after.T <= before.T
    #     flags.push "T failed"
    # end
    unless after.GC <= before.GC + before.GC * 0.5
        flags.push "selection by GC failed"
    end
    flags
end

def check_key_characteristics_for_attenuate_strategy_high_CpGe(before, after)
    flags = []
    unless before.dnaseq != after.dnaseq
        flags.push "seq unchanged"
    end
    unless before.protseq == after.protseq
        flags.push "seq failed"
    end
    unless after.CpG <= before.CpG
        flags.push "CpG failed"
    end
    unless after.T >= before.T
        flags.push "T failed"
    end
    unless after.GC <= before.GC
        flags.push "selection by GC failed"
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
    before = characterise(gene.sequence)

    # strategy attenuate
    enhanced_gene_seqs = tweak_gene_by(gene, "attenuate", 0)
    after = characterise_variants(enhanced_gene_seqs)

    flags = check_key_characteristics_for_attenuate_strategy_low_CpGe(before, after)
    if flags.any?
        puts "::attenuate/ CpGe = 0:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene_seqs.first).join(" ")}\n"
    end

    enhanced_gene_seqs = tweak_gene_by(gene, "attenuate", 0.5)
    after = characterise_variants(enhanced_gene_seqs)
    flags = check_key_characteristics_for_attenuate_strategy_mean_CpGe(before, after)
    if flags.any?
        puts "::attenuate/ CpGe = 0.5:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene_seqs.first).join(" ")}\n"
    end

    enhanced_gene_seqs = tweak_gene_by(gene, "attenuate", 1)
    after = characterise_variants(enhanced_gene_seqs)
    flags = check_key_characteristics_for_attenuate_strategy_high_CpGe(before, after)
    if flags.any?
        puts "::attenuate/ CpGe = 1:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene_seqs.first).join(" ")}\n"
    end

    enhanced_gene_seqs = tweak_gene_by(gene, "attenuate", 1.4)
    if enhanced_gene_seqs.size == 0
        puts "::attenuate/ CpGe > 1:: ##{n} failed: none remaining"
        next
    end
    after = characterise_variants(enhanced_gene_seqs)
    flags = check_key_characteristics_for_attenuate_strategy_high_CpGe(before, after)
    if flags.any?
        puts "::attenuate/ CpGe > 1:: ##{n} failed [#{flags.join(", ")}]: "
            puts "\t#{GeneticCode.split_cdna_into_codons(gene.sequence).join(" ")} => #{GeneticCode.split_cdna_into_codons(enhanced_gene_seqs.first).join(" ")}\n"
    end
end