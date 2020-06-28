# !/usr/bin/env ruby
require 'byebug'
require 'ostruct'

=begin
    A QuickTest style test suite:
    Generate random sequences and check if generated variants meet
    key characteristics of attenuated sequences.

=end

# require .rb files in library (including all subfolders)
Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
    require File.absolute_path(file)
end

def tweak_gene(gene)
    cpg_enrichment = rand(0..1.5)
    tpa_enrichment = rand(0.6..1.4)
    options = OpenStruct.new(
        strategy: "attenuate",
        CpG_enrichment: cpg_enrichment,
        TpA_enrichment: tpa_enrichment,
        stay_in_subbox_for_6folds: false
    )
    enhancer = GeneEnhancer.new(options)
    enhancer.generate_synonymous_genes(gene)

    variants = []
    enhancer.fasta_formatted_gene_variants.each do |fasta|
        lines = fasta.split("\n")
        variants.push lines[1..-1].join("")
    end
    [variants, cpg_enrichment, tpa_enrichment]
end

def filter_variants_by_GC(variants, gene, cpg_enrichment)
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

def characterise_seq(seq)
    OpenStruct.new(
        transl: GeneticCode.translate(seq),
        U: seq.count("T"),
        CpG: seq.scan("CG").size,
        UpA: seq.scan("TA").size,
    )
end

Logging.setup

# randomly build sequence
codons = GeneticCode.valid_codons.reject{|c| GeneticCode.is_stopcodon(c)}
seq = "ATG"
100.times do |sample|
    seq += codons.sample
end
seq += GeneticCode.valid_codons.reject{|c| !GeneticCode.is_stopcodon(c)}.sample

# generate sequence variants
gene = Gene.new
gene.add_cds([seq], [], "test")
variants, cpg_enrichment, tpa_enrichment = tweak_gene(gene)
variants = filter_variants_by_GC(variants, gene, cpg_enrichment)

# test variants
if variants.empty?
    puts "variant selection failed, none remain"
end

before = characterise_seq(gene.sequence)
n_good_variants = 0
variants.each_with_index do |v_seq, ind|
    after = characterise_seq(v_seq)
    if seq == v_seq
        puts "variant [#{ind}]: sequence unchanged"
    end
    if before.protseq != after.protseq
        puts "variant [#{ind}]: made non-synonymous changes"
    end
    if v_seq[-3..-1] != "TAA"
        puts "variant [#{ind}]: didn't set stop to TAA"
    end

    if cpg_enrichment <= 1
        if after.CpG > before.CpG && after.U > before.U && after.UpA > before.UpA
            n_good_variants += 1
        end
    else
        if after.U > before.U
            n_good_variants += 1
        end
    end
end

if n_good_variants == 0
    puts "variant generation failed, none has wanted characteristics"
else
    puts "#{n_good_variants}/#{variants.size} variants qualify"
    puts "target CpG: #{cpg_enrichment}, target UpA: #{tpa_enrichment}"
end