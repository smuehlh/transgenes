class GeneEnhancer

    def initialize(strategy, stay_in_subbox_for_6folds)
        @strategy = strategy
        @stay_in_subbox_for_6folds = stay_in_subbox_for_6folds

        @enhanced_genes = []
    end

    def generate_synonymous_genes(gene)
        @enhanced_genes = 1000.times.collect do |num|
            @variant_number = Counting.ruby_to_human(num)
            generate_synonymous_variant(gene)
        end
    end

    def select_best_gene
        gc_contents = @enhanced_genes.collect{|gene| gene.gc_content}
        distances_to_target = gc_contents.collect{|gc| (gc - target_gc_content).abs}
        ind_best_gene = distances_to_target.index(distances_to_target.min)
        log_selection(ind_best_gene)

        @enhanced_genes[ind_best_gene]
    end

    private

    def target_gc_content
        if @enhanced_genes.first.introns == 0
            # aim for the overall gc-content of 1-exon genes
            0.526380034851897
        else
            # aim for the gc-content of 2-exon genes
            0.5464775145490496
        end
    end

    def generate_synonymous_variant(gene)
        copy = Marshal.load(Marshal.dump(gene))
        copy.tweak_sequence(@strategy, @stay_in_subbox_for_6folds)
        log_generated_variant(copy)

        copy
    end

    def log_generated_variant(gene)
        gc = to_pct(gene.gc_content)
        n_mutated_sites, mutated_sites = gene.log_changed_sites
        desc = "Variant #{@variant_number}: #{gc}% GC, #{n_mutated_sites} changed sites"

        $logger.info GeneToFasta.new(desc, gene.sequence).fasta
        $logger.debug mutated_sites
    end

    def log_selection(variant_ind)
        variant_number = Counting.ruby_to_human(variant_ind)
        target = to_pct(target_gc_content)
        selected = to_pct(@enhanced_genes[variant_ind].gc_content)
        $logger.info "Target GC content: #{target}%"
        $logger.info "Closest match: Variant #{variant_number} (#{selected})%"
    end

    def to_pct(num)
        (num*100).round(2)
    end
end